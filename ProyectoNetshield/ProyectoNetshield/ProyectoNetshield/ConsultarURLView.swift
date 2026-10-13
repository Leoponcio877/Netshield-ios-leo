import SwiftUI

struct ConsultarURLView: View {
    @EnvironmentObject var appState: AppState
    @State private var query: String = ""
    @State private var lastResult: URLCheckResult?
    @State private var showResultSheet = false
    @State private var errorText: String?
    @State private var isChecking = false

    var body: some View {
        NavigationStack {
            ZStack {
                NSTheme.navy.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        HStack {
                            Image(systemName: "magnifyingglass").foregroundColor(.gray)
                            TextField("Pega o escribe la URL a verificar", text: $query).foregroundColor(.black)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .submitLabel(.search)
                                .onSubmit { runCheck() }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                        VStack(spacing: 10) {
                            Image(systemName: "magnifyingglass.circle")
                                .font(.system(size: 54))
                                .foregroundColor(NSTheme.brandYellow)
                            Text("Verifica antes de confiar")
                                .font(.title3.bold())
                                .foregroundColor(.white)
                            Text("Pega cualquier enlace sospechoso y comprueba si la comunidad ya lo reportó.")
                                .font(.subheadline)
                                .foregroundColor(NSTheme.textMuted)
                                .multilineTextAlignment(.center)

                            Button(isChecking ? "Verificando..." : "Verificar ahora") { runCheck() }
                                .buttonStyle(PrimaryButtonStyle(background: NSTheme.brandYellow))
                                .disabled(isChecking)
                                .padding(.top, 6)
                        }
                        .padding(.vertical, 10)

                        if let errorText {
                            Text(errorText)
                                .font(.footnote)
                                .foregroundColor(NSTheme.dangerRed)
                        }

                        if !appState.urlSearchHistory.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Búsquedas recientes")
                                    .font(.headline)
                                    .foregroundColor(.white)

                                VStack(spacing: 10) {
                                    ForEach(appState.urlSearchHistory) { result in
                                        Button {
                                            query = result.url
                                            lastResult = result
                                            showResultSheet = true
                                        } label: {
                                            HStack {
                                                Image(systemName: result.risk.icon)
                                                    .foregroundColor(result.risk.color)
                                                Text(result.url)
                                                    .foregroundColor(.black)
                                                    .lineLimit(1)
                                                Spacer()
                                                Image(systemName: "chevron.right")
                                                    .foregroundColor(.gray)
                                            }
                                            .padding(14)
                                            .background(NSTheme.cardBackground)
                                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                        }
                                    }
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Sitios Reportados")
                                .font(.subheadline)
                                .foregroundColor(NSTheme.navy.opacity(0.8))
                            HStack(alignment: .lastTextBaseline) {
                                Text("\(appState.databaseSiteCount)")
                                    .font(.system(size: 34, weight: .bold))
                                Spacer()
                                Image(systemName: "chart.bar.fill")
                                    .font(.title)
                            }
                            .foregroundColor(NSTheme.navy)
                            Text("+\(appState.reportsThisWeek) reportes esta semana")
                                .font(.caption)
                                .foregroundColor(NSTheme.navy.opacity(0.7))
                        }
                        .padding(18)
                        .background(NSTheme.brandYellow)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Consultar URL")
            .navigationBarTitleDisplayMode(.inline)
            .task { await appState.loadStats(category: nil, country: nil) }
        }
        .sheet(isPresented: $showResultSheet) {
            if let lastResult {
                URLResultSheet(result: lastResult)
                    .presentationDetents([.medium])
            }
        }
    }

    private func runCheck() {
        let value = query.trimmingCharacters(in: .whitespaces)
        guard !value.isEmpty, !isChecking else { return }
        errorText = nil
        isChecking = true
        Task {
            if let risk = await appState.checkURL(value) {
                lastResult = URLCheckResult(url: value, risk: risk)
                showResultSheet = true
            } else {
                errorText = appState.authError
            }
            isChecking = false
        }
    }
}

struct URLResultSheet: View {
    let result: URLCheckResult

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: result.risk.icon)
                .font(.system(size: 50))
                .foregroundColor(result.risk.color)
                .padding(.top, 30)

            Text(result.risk.rawValue)
                .font(.title2.bold())

            Text(result.url)
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Text(message(for: result.risk))
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.horizontal, 24)

            Spacer()
        }
        .padding()
    }

    private func message(for risk: RiskLevel) -> String {
        switch risk {
        case .alto:
            return "Este sitio ha sido reportado y verificado como fraudulento. No ingreses tus datos ni realices pagos."
        case .medio:
            return "Hay reportes de la comunidad en revisión, pero aún no están confirmados. Ten precaución."
        case .seguro:
            return "No hay reportes de este sitio en NetShield. Eso no garantiza que sea seguro: verifica antes de ingresar datos."
        }
    }
}

#Preview {
    ConsultarURLView().environmentObject(AppState())
}
