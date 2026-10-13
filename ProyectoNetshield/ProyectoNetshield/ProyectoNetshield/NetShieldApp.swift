import SwiftUI

@main
struct NetShieldApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .preferredColorScheme(.dark)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            if appState.isLoggedIn {
                MainTabView()
                    .transition(.opacity)
            } else {
                LoginView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: appState.isLoggedIn)
    }
}

struct MainTabView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            HomeView()
                .tabItem { Label("Inicio", systemImage: "house.fill") }
                .tag(AppTab.home)

            ConsultarURLView()
                .tabItem { Label("Buscar", systemImage: "magnifyingglass") }
                .tag(AppTab.buscar)

            AlertasView()
                .tabItem { Label("Alertas", systemImage: "bell.fill") }
                .tag(AppTab.alertas)

            PerfilView()
                .tabItem { Label("Perfil", systemImage: "person.fill") }
                .tag(AppTab.perfil)
        }
        .tint(NSTheme.brandYellow)
    }
}
