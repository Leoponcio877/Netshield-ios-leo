import Foundation
import Combine
import UIKit

enum AppTab: Hashable {
    case home, buscar, alertas, perfil
}

@MainActor
final class AppState: ObservableObject {

    // MARK: Sesión
    @Published var isLoggedIn = false
    @Published var currentUserName = ""
    @Published var currentUserEmail = ""
    @Published var currentUserCountry = ""
    @Published var authError: String?

    // MARK: Datos (todos vienen del backend)
    @Published var reports: [FraudReport] = []
    @Published var alerts: [FraudAlert] = []
    @Published var urlSearchHistory: [URLCheckResult] = []   // búsquedas de esta sesión
    @Published var stats: StatsDTO?
    @Published var databaseSiteCount = 0
    @Published var reportsThisWeek = 0
    @Published var selectedTab: AppTab = .home
    @Published var profileImageData: Data?

    init() { restoreSession() }

    // MARK: Sesión

    private func restoreSession() {
        guard TokenStore.accessToken != nil else { return }
        isLoggedIn = true
        Task { await refreshAll() }
    }

    func login(email: String, password: String) async -> Bool {
        authError = nil
        do {
            try await APIClient.shared.login(email: email, password: password)
            isLoggedIn = true
            await refreshAll()
            return true
        } catch {
            authError = error.localizedDescription
            return false
        }
    }

    func register(username: String, email: String, password: String, country: String) async -> Bool {
        authError = nil
        do {
            try await APIClient.shared.register(name: username, email: email, password: password, country: country)
            // No se inicia sesión aquí: el usuario debe volver al login e ingresar con su cuenta nueva.
            return true
        } catch {
            authError = error.localizedDescription
            return false
        }
    }

    func logout() {
        Task { await APIClient.shared.logout() }
        isLoggedIn = false
        reports = []
        alerts = []
        urlSearchHistory = []
        stats = nil
        profileImageData = nil
        currentUserName = ""
        currentUserEmail = ""
        currentUserCountry = ""
    }

    private func handle(_ error: Error) {
        if case APIError.unauthorized = error { logout() } else { authError = error.localizedDescription }
    }

    func refreshAll() async {
        await loadProfile()
        await loadMyReports()
        await loadAlerts()
        await loadStats(category: nil, country: nil)
    }

    // MARK: Perfil

    func loadProfile() async {
        do {
            let profile = try await APIClient.shared.profile()
            currentUserName = profile.name
            currentUserEmail = profile.email
            currentUserCountry = profile.country ?? ""
            if let path = profile.photoUrl {
                profileImageData = await APIClient.shared.imageData(path: path)
            }
        } catch { handle(error) }
    }

    func updatePhoto(_ original: Data) async {
        guard let jpeg = Self.resizedJPEG(original) else { return }
        do {
            _ = try await APIClient.shared.uploadProfilePhoto(jpeg: jpeg)
            profileImageData = jpeg
        } catch { handle(error) }
    }

    /// Reduce la imagen a 1024 px como máximo para no superar el límite del servidor.
    private static func resizedJPEG(_ data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let scale = min(1, 1024 / max(image.size.width, image.size.height))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let resized = UIGraphicsImageRenderer(size: size).image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
        return resized.jpegData(compressionQuality: 0.7)
    }

    // MARK: Reportes

    func loadMyReports() async {
        do {
            reports = try await APIClient.shared.myReports().map { item in
                FraudReport(url: item.url,
                            category: ReportCategory(serverName: item.category),
                            categoryName: item.category,
                            description: item.description,
                            dateCreated: item.createdAt,
                            status: ReportStatus(rawValue: item.status) ?? .enRevision)
            }
        } catch { handle(error) }
    }

    func submitReport(url: String, category: ReportCategory, customName: String?,
                      description: String, evidence: Data?) async -> Bool {
        authError = nil
        do {
            try await APIClient.shared.submitReport(url: url, category: category, customName: customName,
                                                    description: description, evidence: evidence)
            await loadMyReports()
            await loadAlerts()
            await loadStats(category: nil, country: nil)
            return true
        } catch {
            authError = error.localizedDescription
            return false
        }
    }

    var pendingReportsCount: Int {
        reports.filter { $0.status == .enRevision }.count
    }

    // MARK: Alertas

    func loadAlerts() async {
        do {
            alerts = try await APIClient.shared.alerts().map { item in
                FraudAlert(url: item.url,
                           category: ReportCategory(serverName: item.category),
                           categoryName: item.category,
                           risk: RiskLevel(code: item.risk),
                           descriptionText: item.description,
                           timeAgo: Self.relative(item.lastReport),
                           verified: item.verified)
            }
        } catch { handle(error) }
    }

    func alerts(for category: ReportCategory?) -> [FraudAlert] {
        guard let category else { return alerts }
        return alerts.filter { $0.category == category }
    }

    private static func relative(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "es_MX")
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    // MARK: Consultar URL

    /// Devuelve nil si falló (el motivo queda en authError).
    func checkURL(_ rawURL: String) async -> RiskLevel? {
        authError = nil
        do {
            let result = try await APIClient.shared.searchSite(url: rawURL)
            let risk = RiskLevel(code: result.risk)
            urlSearchHistory.removeAll { $0.url.lowercased() == rawURL.lowercased() }
            urlSearchHistory.insert(URLCheckResult(url: rawURL, risk: risk), at: 0)
            if urlSearchHistory.count > 10 { urlSearchHistory.removeLast() }
            return risk
        } catch {
            handle(error)
            return nil
        }
    }

    // MARK: Estadísticas

    func loadStats(category: String?, country: String?) async {
        do {
            let result = try await APIClient.shared.statistics(category: category, country: country)
            stats = result
            databaseSiteCount = result.summary.sites
            reportsThisWeek = result.summary.reportsThisWeek
        } catch { handle(error) }
    }

    func totalsByCategory() -> [(category: String, count: Int)] {
        stats?.byCategory.map { ($0.category, $0.total) } ?? []
    }

    func monthlyStats() -> [MonthlyStat] {
        let parser = DateFormatter()
        parser.dateFormat = "yyyy-MM"
        let label = DateFormatter()
        label.locale = Locale(identifier: "es_MX")
        label.dateFormat = "MMM yyyy"

        return stats?.byMonth.map { item in
            let text = parser.date(from: item.month).map { label.string(from: $0) } ?? item.month
            return MonthlyStat(category: item.category, month: text, count: item.total)
        } ?? []
    }
}