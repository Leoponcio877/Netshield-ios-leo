import SwiftUI
import PhotosUI

struct MisReportesView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack {
            NSTheme.navy.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 12) {
                    if appState.reports.isEmpty {
                        Text("Aún no has enviado reportes.")
                            .foregroundColor(NSTheme.textMuted)
                            .padding(.top, 60)
                    } else {
                        ForEach(appState.reports) { report in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: report.category.icon)
                                        .foregroundColor(report.category.tintColor)
                                    Text(report.url)
                                        .font(.headline)
                                        .foregroundColor(.black)
                                        .lineLimit(1)
                                    Spacer()
                                    Text(report.status.rawValue)
                                        .font(.caption.weight(.semibold))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(report.status.color.opacity(0.15))
                                        .foregroundColor(report.status.color)
                                        .clipShape(Capsule())
                                }
                                Text(report.categoryName)
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(report.category.tintColor)
                                if !report.description.isEmpty {
                                    Text(report.description)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                Text(report.dateCreated, style: .date)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(NSTheme.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                    }
                }
                .padding(20)
            }
            .refreshable { await appState.loadMyReports() }
        }
        .navigationTitle("Mis reportes")
        .navigationBarTitleDisplayMode(.inline)
        .task { await appState.loadMyReports() }
    }
}

struct PerfilView: View {

    @EnvironmentObject var appState: AppState
    @State private var showLogoutAlert = false
    @State private var selectedPhoto: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            ZStack {
                NSTheme.navy.ignoresSafeArea()

                VStack(spacing: 24) {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        ZStack(alignment: .bottomTrailing) {
                            if let data = appState.profileImageData, let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 90, height: 90)
                                    .clipShape(Circle())
                            } else {
                                ZStack {
                                    Circle()
                                        .fill(NSTheme.accent.opacity(0.2))
                                        .frame(width: 90, height: 90)
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(NSTheme.accent)
                                }
                            }
                            ZStack {
                                Circle().fill(NSTheme.brandYellow).frame(width: 28, height: 28)
                                Image(systemName: "camera.fill")
                                    .font(.caption)
                                    .foregroundColor(NSTheme.navy)
                            }
                            .overlay(Circle().stroke(NSTheme.navy, lineWidth: 2))
                        }
                    }
                    .padding(.top, 30)
                    .onChange(of: selectedPhoto) { _, newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                await appState.updatePhoto(data)
                            }
                        }
                    }

                    VStack(spacing: 4) {
                        Text(appState.currentUserName.isEmpty ? "Usuario" : appState.currentUserName)
                            .font(.title3.bold())
                            .foregroundColor(.white)
                        Text(appState.currentUserEmail)
                            .font(.subheadline)
                            .foregroundColor(NSTheme.textMuted)
                        if !appState.currentUserCountry.isEmpty {
                            Text(appState.currentUserCountry)
                                .font(.caption)
                                .foregroundColor(NSTheme.textMuted)
                        }
                    }

                    VStack(spacing: 0) {
                        NavigationLink {
                            MisReportesView()
                        } label: {
                            ProfileRow(icon: "list.clipboard.fill", title: "Mis reportes",
                                       trailing: "\(appState.reports.count)")
                        }
                        Divider()
                        NavigationLink {
                            AlertasView()
                        } label: {
                            ProfileRow(icon: "bell.fill", title: "Alertas", trailing: "\(appState.alerts.count)")
                        }

                        Divider()
                        NavigationLink {
                            SettingsView()
                        } label: {
                            ProfileRow(icon: "gearshape.fill", title: "Configuración", trailing: nil)
                        }

                        Divider()
                        NavigationLink {
                            EstadisticasView()
                        } label: {
                            ProfileRow(icon: "chart.bar.fill", title: "Estadísticas", trailing: nil)
                        }
                    }
                    .background(NSTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.horizontal, 20)

                    Spacer()

                    Button(role: .destructive) {
                        showLogoutAlert = true
                    } label: {
                        Text("Cerrar sesión")
                            .fontWeight(.semibold)
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Perfil")
            .navigationBarTitleDisplayMode(.inline)
            .task { await appState.loadProfile() }
            .alert("¿Cerrar sesión?", isPresented: $showLogoutAlert) {
                Button("Cancelar", role: .cancel) {}
                Button("Cerrar sesión", role: .destructive) { appState.logout() }
            }
        }
    }
}

struct ProfileRow: View {
    let icon: String
    let title: String
    let trailing: String?

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(NSTheme.navy)
                .frame(width: 24)
            Text(title)
                .foregroundColor(.black)
            Spacer()
            if let trailing {
                Text(trailing)
                    .foregroundColor(.gray)
            }
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.caption)
        }
        .padding(16)
    }
}

#Preview {
    PerfilView().environmentObject(AppState())
}
