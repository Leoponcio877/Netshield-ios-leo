import SwiftUI

// MARK: - Nivel de riesgo

enum RiskLevel: String, Codable {
    case alto = "Alto riesgo"
    case medio = "Riesgo medio"
    case seguro = "Seguro"

    /// Código que envía el backend: high, medium, safe.
    init(code: String) {
        switch code {
        case "high": self = .alto
        case "medium": self = .medio
        default: self = .seguro
        }
    }

    var color: Color {
        switch self {
        case .alto: return NSTheme.dangerRed
        case .medio: return NSTheme.warning
        case .seguro: return NSTheme.safeGreen
        }
    }

    var icon: String {
        switch self {
        case .alto: return "exclamationmark.triangle.fill"
        case .medio: return "exclamationmark.circle.fill"
        case .seguro: return "checkmark.seal.fill"
        }
    }
}

// MARK: - Categoría de reporte

enum ReportCategory: String, Codable, CaseIterable, Identifiable {
    case banco = "Banco"
    case compra = "Compra en línea"
    case escuela = "Escuela"
    case redSocial = "Red social"
    case otro = "Otro"

    var id: String { rawValue }

    /// Nombre guardado en el backend ("Bancos" en la BD).
    var serverName: String { self == .banco ? "Bancos" : rawValue }

    /// Interpreta el nombre que llega del backend; las personalizadas son .otro.
    init(serverName: String) {
        let key = serverName.folding(options: .diacriticInsensitive, locale: .current)
            .lowercased().filter { $0.isLetter }
        switch key {
        case "banco", "bancos": self = .banco
        case "compraenlinea": self = .compra
        case "escuela": self = .escuela
        case "redsocial": self = .redSocial
        default: self = .otro
        }
    }

    var icon: String {
        switch self {
        case .banco: return "creditcard.fill"
        case .compra: return "bag.fill"
        case .escuela: return "book.fill"
        case .redSocial: return "person.fill"
        case .otro: return "questionmark.circle.fill"
        }
    }

    var tintColor: Color {
        switch self {
        case .banco: return .blue
        case .compra: return .orange
        case .escuela: return .green
        case .redSocial: return .purple
        case .otro: return .gray
        }
    }
}

// MARK: - Reporte del usuario

enum ReportStatus: String, Codable {
    case enRevision = "En revisión"
    case aprobado = "Aprobado"
    case desaprobado = "Desaprobado"

    var color: Color {
        switch self {
        case .enRevision: return NSTheme.warning
        case .aprobado: return NSTheme.safeGreen
        case .desaprobado: return NSTheme.dangerRed
        }
    }
}

struct FraudReport: Identifiable, Codable {
    let id: UUID
    var url: String
    var category: ReportCategory
    var categoryName: String
    var description: String
    var dateCreated: Date
    var status: ReportStatus

    init(url: String, category: ReportCategory, categoryName: String? = nil,
         description: String, dateCreated: Date = Date(), status: ReportStatus = .enRevision) {
        self.id = UUID()
        self.url = url
        self.category = category
        self.categoryName = categoryName ?? category.rawValue
        self.description = description
        self.dateCreated = dateCreated
        self.status = status
    }
}

// MARK: - Alerta comunitaria

struct FraudAlert: Identifiable, Codable {
    let id: UUID
    var url: String
    var category: ReportCategory
    var categoryName: String
    var risk: RiskLevel
    var descriptionText: String
    var timeAgo: String
    var verified: Bool

    init(url: String, category: ReportCategory, categoryName: String? = nil, risk: RiskLevel,
         descriptionText: String, timeAgo: String, verified: Bool = true) {
        self.id = UUID()
        self.url = url
        self.category = category
        self.categoryName = categoryName ?? category.rawValue
        self.risk = risk
        self.descriptionText = descriptionText
        self.timeAgo = timeAgo
        self.verified = verified
    }
}

// MARK: - Resultado de búsqueda de URL

struct URLCheckResult: Identifiable, Codable {
    let id: UUID
    var url: String
    var risk: RiskLevel
    var dateChecked: Date

    init(url: String, risk: RiskLevel) {
        self.id = UUID()
        self.url = url
        self.risk = risk
        self.dateChecked = Date()
    }
}

// MARK: - Estadística mensual por categoría

struct MonthlyStat: Identifiable {
    let id = UUID()
    let category: String
    let month: String
    let count: Int
}