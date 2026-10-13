import Foundation
import Security

enum APIConfig {
    static let baseURL = URL(string: "http://172.20.10.2:3000")!
}

enum APIError: LocalizedError {
    case server(String)
    case unauthorized
    case network

    var errorDescription: String? {
        switch self {
        case .server(let message): return message
        case .unauthorized: return "Tu sesión expiró. Inicia sesión de nuevo."
        case .network: return "No se pudo conectar con el servidor."
        }
    }
}

/// Tokens en el Keychain (nunca en UserDefaults).
enum TokenStore {
    private static func base(_ key: String) -> [String: Any] {
        [kSecClass as String: kSecClassGenericPassword, kSecAttrAccount as String: key]
    }

    private static func save(_ value: String, key: String) {
        SecItemDelete(base(key) as CFDictionary)
        var item = base(key)
        item[kSecValueData as String] = Data(value.utf8)
        item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(item as CFDictionary, nil)
    }

    private static func read(_ key: String) -> String? {
        var query = base(key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static var accessToken: String? {
        get { read("accessToken") }
        set { if let v = newValue { save(v, key: "accessToken") } else { SecItemDelete(base("accessToken") as CFDictionary) } }
    }

    static var refreshToken: String? {
        get { read("refreshToken") }
        set { if let v = newValue { save(v, key: "refreshToken") } else { SecItemDelete(base("refreshToken") as CFDictionary) } }
    }

    static func clearAll() { accessToken = nil; refreshToken = nil }
}

// MARK: - Respuestas del backend

struct TokensResponse: Decodable { let accessToken: String; let refreshToken: String }
struct AccessResponse: Decodable { let accessToken: String }

struct ReportDTO: Decodable {
    let id: Int
    let url: String
    let category: String
    let status: String
    let description: String
    let createdAt: Date
    let evidenceUrls: [String]
}

struct AlertDTO: Decodable {
    let id: Int
    let url: String
    let category: String
    let risk: String
    let verified: Bool
    let description: String
    let lastReport: Date
}

struct SiteSearchDTO: Decodable {
    let url: String
    let risk: String
    let reports: Int
    let approved: Int
    let lastReport: Date?
}

struct StatsDTO: Decodable {
    struct Summary: Decodable { let sites: Int; let reportsThisWeek: Int }
    struct CategoryTotal: Decodable { let category: String; let total: Int }
    struct MonthTotal: Decodable { let month: String; let category: String; let total: Int }
    let summary: Summary
    let byCategory: [CategoryTotal]
    let byMonth: [MonthTotal]
    let countries: [String]
}

struct ProfileDTO: Decodable {
    let name: String
    let email: String
    let country: String?
    let photoUrl: String?
    let registeredAt: String
}

actor APIClient {
    static let shared = APIClient()

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        let withMs = ISO8601DateFormatter()
        withMs.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let plain = ISO8601DateFormatter()
        decoder.dateDecodingStrategy = .custom { d in
            let text = try d.singleValueContainer().decode(String.self)
            if let date = withMs.date(from: text) ?? plain.date(from: text) { return date }
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Fecha inválida"))
        }
        return decoder
    }()

    // MARK: Sesión

    func register(name: String, email: String, password: String, country: String) async throws {
        _ = try await send("POST", "/auth/register",
                           json: ["name": name, "email": email, "password": password, "country": country],
                           authenticated: false)
    }

    func login(email: String, password: String) async throws {
        let data = try await send("POST", "/auth/login",
                                  json: ["email": email, "password": password], authenticated: false)
        let tokens = try decoder.decode(TokensResponse.self, from: data)
        TokenStore.accessToken = tokens.accessToken
        TokenStore.refreshToken = tokens.refreshToken
    }

    func logout() { TokenStore.clearAll() }

    // MARK: Perfil

    func profile() async throws -> ProfileDTO {
        try decoder.decode(ProfileDTO.self, from: try await send("GET", "/users/profile"))
    }

    func uploadProfilePhoto(jpeg: Data) async throws -> ProfileDTO {
        let data = try await upload("/users/profile/photo", jpeg: jpeg)
        return try decoder.decode(ProfileDTO.self, from: data)
    }

    func changePassword(current: String, new: String) async throws {
        _ = try await send("PATCH", "/users/profile/password",
                           json: ["currentPassword": current, "newPassword": new])
    }

    /// Imágenes de /uploads (públicas).
    func imageData(path: String) async -> Data? {
        guard let url = URL(string: path, relativeTo: APIConfig.baseURL),
              let (data, response) = try? await URLSession.shared.data(from: url),
              (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }
        return data
    }

    // MARK: Reportes

    func myReports() async throws -> [ReportDTO] {
        try decoder.decode([ReportDTO].self, from: try await send("GET", "/reports"))
    }

    func submitReport(url: String, category: ReportCategory, customName: String?,
                      description: String, evidence: Data?) async throws {
        var body = ["url": url, "subcategory": category.serverName, "description": description]
        if category == .otro, let customName { body["customSubcategory"] = customName }

        let created = try decoder.decode(ReportDTO.self, from: try await send("POST", "/reports", json: body))
        if let evidence {
            _ = try await upload("/reports/\(created.id)/evidence", jpeg: evidence)
        }
    }

    // MARK: Comunidad

    func searchSite(url: String) async throws -> SiteSearchDTO {
        let data = try await send("GET", "/sites/search", query: [URLQueryItem(name: "url", value: url)])
        return try decoder.decode(SiteSearchDTO.self, from: data)
    }

    func alerts() async throws -> [AlertDTO] {
        try decoder.decode([AlertDTO].self, from: try await send("GET", "/alerts"))
    }

    func statistics(category: String?, country: String?) async throws -> StatsDTO {
        var query: [URLQueryItem] = []
        if let category { query.append(URLQueryItem(name: "category", value: category)) }
        if let country { query.append(URLQueryItem(name: "country", value: country)) }
        return try decoder.decode(StatsDTO.self, from: try await send("GET", "/statistics", query: query))
    }

    // MARK: Núcleo

    private func upload(_ path: String, jpeg: Data) async throws -> Data {
        let boundary = UUID().uuidString
        var body = Data()
        body.append(Data("--\(boundary)\r\n".utf8))
        body.append(Data("Content-Disposition: form-data; name=\"file\"; filename=\"imagen.jpg\"\r\n".utf8))
        body.append(Data("Content-Type: image/jpeg\r\n\r\n".utf8))
        body.append(jpeg)
        body.append(Data("\r\n--\(boundary)--\r\n".utf8))
        return try await send("POST", path, raw: body, contentType: "multipart/form-data; boundary=\(boundary)")
    }

    private func send(_ method: String, _ path: String,
                      json: [String: String]? = nil,
                      raw: Data? = nil,
                      query: [URLQueryItem] = [],
                      contentType: String = "application/json",
                      authenticated: Bool = true,
                      isRetry: Bool = false) async throws -> Data {
        var components = URLComponents(url: APIConfig.baseURL.appendingPathComponent(path),
                                       resolvingAgainstBaseURL: false)!
        if !query.isEmpty { components.queryItems = query }

        var request = URLRequest(url: components.url!)
        request.httpMethod = method
        request.timeoutInterval = 20

        if let json { request.httpBody = try JSONEncoder().encode(json) }
        if let raw { request.httpBody = raw }
        if request.httpBody != nil { request.setValue(contentType, forHTTPHeaderField: "Content-Type") }
        if authenticated, let token = TokenStore.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let data: Data
        let response: URLResponse
        do { (data, response) = try await URLSession.shared.data(for: request) }
        catch { throw APIError.network }

        guard let http = response as? HTTPURLResponse else { throw APIError.network }

        if http.statusCode == 401 && authenticated {
            if !isRetry, await refreshAccessToken() {
                return try await send(method, path, json: json, raw: raw, query: query,
                                      contentType: contentType, isRetry: true)
            }
            TokenStore.clearAll()
            throw APIError.unauthorized
        }

        guard (200..<300).contains(http.statusCode) else {
            throw APIError.server(Self.message(from: data, status: http.statusCode))
        }
        return data
    }

    private func refreshAccessToken() async -> Bool {
        guard let refresh = TokenStore.refreshToken else { return false }
        var request = URLRequest(url: APIConfig.baseURL.appendingPathComponent("/auth/refresh"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(["refreshToken": refresh])

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse, http.statusCode < 300,
              let result = try? decoder.decode(AccessResponse.self, from: data) else { return false }

        TokenStore.accessToken = result.accessToken
        return true
    }

    /// Mensajes legibles; los 5xx no exponen detalles internos.
    private static func message(from data: Data, status: Int) -> String {
        if status >= 500 { return "Ocurrió un error en el servidor. Intenta más tarde." }
        if status == 429 { return "Demasiados intentos. Espera un minuto." }
        let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        if let text = json?["message"] as? String { return text }
        if let list = json?["message"] as? [String] { return list.joined(separator: ", ") }
        return "Error \(status)"
    }
}
