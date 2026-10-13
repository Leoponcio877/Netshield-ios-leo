import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var showNewReport = false

    var body: some View {
        NavigationStack {
            ZStack {
                NSTheme.navy.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {

                        // Encabezado
                        HStack(spacing: 12) {
                            Image("logo").resizable().scaledToFit().frame(width: 52, height: 52).clipShape(RoundedRectangle(cornerRadius:12, style: .continuous))
                            VStack(alignment: .leading) {
                                Text("Hola, \(appState.currentUserName.isEmpty ? "Usuario" : appState.currentUserName)")
                                    .font(.title3.bold())
                                    .foregroundColor(.white)
                                Text("Bienvenido")
                                    .font(.subheadline)
                                    .foregroundColor(NSTheme.textMuted)
                            }
                            Spacer()
                        }
                        .padding(.top, 8)

                        // Botón reportar fraude
                        Button {
                            showNewReport = true
                        } label: {
                            HStack {
                                Image(systemName: "exclamationmark.octagon.fill")
                                Text("Reportar un fraude").fontWeight(.semibold)
                                Spacer()
                                Image(systemName: "arrow.right.circle")
                            }
                            .font(.headline)
                            .foregroundColor(NSTheme.navy)
                            .padding(20)
                            .background(NSTheme.brandYellow)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }

                        // Acceso rápido
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Acceso rápido")
                                .font(.headline)
                                .foregroundColor(.white)

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                                Button {
                                    appState.selectedTab = .buscar
                                } label: {
                                    QuickAccessCard(icon: "magnifyingglass", iconColor: NSTheme.brandYellow,
                                                    title: "Consultar URL", subtitle: "Verificar sitio")
                                }

                                NavigationLink {
                                    EstadisticasView()
                                } label: {
                                    QuickAccessCard(icon: "chart.bar.fill", iconColor: NSTheme.brandYellow,
                                                    title: "Estadísticas", subtitle: "Ver tendencias")
                                }

                                Button {
                                    appState.selectedTab = .alertas
                                } label: {
                                    QuickAccessCard(icon: "exclamationmark.triangle.fill", iconColor: NSTheme.brandYellow,
                                                    title: "Alertas comunes", subtitle: todayString())
                                }

                                NavigationLink {
                                    MisReportesView()
                                } label: {
                                    QuickAccessCard(icon: "list.clipboard.fill", iconColor: NSTheme.brandYellow,
                                                    title: "Mis reportes", subtitle: "\(appState.pendingReportsCount) en revisión")
                                }
                            }
                        }

                        // Alertas recientes
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Alertas recientes")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Spacer()
                                Button {
                                    appState.selectedTab = .alertas
                                } label: {
                                    HStack(spacing: 4) {
                                        Text("Ver todas")
                                        Image(systemName: "arrow.right.circle")
                                    }
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(NSTheme.brandYellow)
                                }
                            }

                            VStack(spacing: 10) {
                                ForEach(appState.alerts.prefix(3)) { alert in
                                    NavigationLink {
                                        AlertDetailScreen(alert: alert)
                                    } label: {
                                        RecentAlertRow(alert: alert)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showNewReport) {
                NewReportView()
            }
        }
    }

    private func todayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "'hoy' d 'de' MMMM"
        formatter.locale = Locale(identifier: "es_MX")
        return formatter.string(from: Date())
    }
}

struct QuickAccessCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iconColor)
            Text(title)
                .font(.headline)
                .foregroundColor(.black)
                .fixedSize(horizontal: false, vertical: true)
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(NSTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct RecentAlertRow: View {
    let alert: FraudAlert

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: alert.risk.icon)
                .foregroundColor(alert.risk.color)
                .font(.title3)

            VStack(alignment: .leading, spacing: 4) {
                Text(alert.url)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.black)
                    .lineLimit(1)
                HStack(spacing: 8) {
                    Text(alert.risk.rawValue)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(alert.risk.color.opacity(0.15))
                        .foregroundColor(alert.risk.color)
                        .clipShape(Capsule())
                    Text(alert.timeAgo)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            Spacer()
            Image(systemName: "arrow.up.right.square")
                .foregroundColor(.gray)
        }
        .padding(14)
        .background(NSTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

#Preview {
    HomeView().environmentObject(AppState())
}
