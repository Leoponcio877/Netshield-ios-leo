import SwiftUI
import Charts

struct EstadisticasView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedFilter: ReportCategory?
    @State private var selectedCountry: String?

    private let filters: [(label: String, category: ReportCategory?)] = [
        ("Todos", nil),
        ("Bancos", .banco),
        ("Compras", .compra),
        ("Escuelas", .escuela),
        ("Red social", .redSocial)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                NSTheme.navy.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(filters, id: \.label) { filter in
                                    FilterChip(title: filter.label, isSelected: selectedFilter == filter.category) {
                                        selectedFilter = filter.category
                                    }
                                }
                                countryMenu
                            }
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Alertas por categoría")
                                .font(.headline)
                                .foregroundColor(.black)

                            if appState.totalsByCategory().isEmpty {
                                emptyText
                            } else {
                                Chart(appState.totalsByCategory(), id: \.category) { item in
                                    BarMark(
                                        x: .value("Categoría", item.category),
                                        y: .value("Reportes", item.count)
                                    )
                                    .foregroundStyle(NSTheme.accent)
                                    .cornerRadius(6)
                                }
                                .frame(height: 200)
                                .chartXAxis {
                                    AxisMarks { _ in
                                        AxisValueLabel().font(.caption2)
                                    }
                                }
                            }
                        }
                        .padding(18)
                        .background(NSTheme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Tendencia por categoría")
                                .font(.headline)
                                .foregroundColor(.black)

                            if appState.monthlyStats().isEmpty {
                                emptyText
                            } else {
                                Chart(appState.monthlyStats(), id: \.id) { stat in
                                    LineMark(
                                        x: .value("Mes", stat.month),
                                        y: .value("Reportes", stat.count)
                                    )
                                    .foregroundStyle(by: .value("Categoría", stat.category))
                                    .symbol(by: .value("Categoría", stat.category))
                                }
                                .frame(height: 260)
                                .chartLegend(position: .bottom, spacing: 10)
                            }
                        }
                        .padding(18)
                        .background(NSTheme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Estadísticas")
            .navigationBarTitleDisplayMode(.inline)
            .task(id: "\(selectedFilter?.rawValue ?? "")|\(selectedCountry ?? "")") {
                await appState.loadStats(category: selectedFilter?.serverName, country: selectedCountry)
            }
        }
    }

    private var emptyText: some View {
        Text("Aún no hay reportes aprobados con estos filtros.")
            .font(.subheadline)
            .foregroundColor(.gray)
            .frame(maxWidth: .infinity, minHeight: 80)
    }

    private var countryMenu: some View {
        Menu {
            Button("Todos los países") { selectedCountry = nil }
            ForEach(appState.stats?.countries ?? [], id: \.self) { country in
                Button(country) { selectedCountry = country }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "globe")
                Text(selectedCountry ?? "País")
            }
            .font(.subheadline.weight(.semibold))
            .foregroundColor(selectedCountry == nil ? .white : NSTheme.navy)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(selectedCountry == nil ? NSTheme.navyLight : NSTheme.accent)
            .clipShape(Capsule())
        }
    }
}

#Preview {
    EstadisticasView().environmentObject(AppState())
}
