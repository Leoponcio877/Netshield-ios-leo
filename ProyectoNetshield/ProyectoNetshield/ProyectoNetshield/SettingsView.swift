import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("alertasAltoRiesgo") private var alertasAltoRiesgo = true

    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var passwordMessage: String?
    @State private var passwordOK = false
    @State private var isSaving = false

    var body: some View {
        ZStack {
            NSTheme.navy.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 0) {
                        Toggle("Notificaciones", isOn: $notificationsEnabled)
                            .padding(16).foregroundColor(.black)
                        Divider()
                        Toggle("Alertas de alto riesgo", isOn: $alertasAltoRiesgo)
                            .padding(16).foregroundColor(.black)
                    }
                    .tint(NSTheme.brandYellow)
                    .background(NSTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Cuenta").font(.caption).foregroundColor(.gray)
                        Text(appState.currentUserEmail).foregroundColor(.black)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(NSTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Cambiar contraseña").font(.headline).foregroundColor(.black)
                        NSTextField(placeholder: "Contraseña actual", text: $currentPassword, isSecure: true)
                        NSTextField(placeholder: "Nueva contraseña (mínimo 8)", text: $newPassword, isSecure: true)

                        if let passwordMessage {
                            Text(passwordMessage)
                                .font(.footnote)
                                .foregroundColor(passwordOK ? NSTheme.safeGreen : NSTheme.dangerRed)
                        }

                        Button(isSaving ? "Guardando..." : "Actualizar contraseña") { changePassword() }
                            .buttonStyle(PrimaryButtonStyle(background: NSTheme.navy, foreground: .white))
                            .disabled(isSaving)
                    }
                    .padding(16)
                    .background(NSTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding(20)
            }
        }
        .navigationTitle("Configuración")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func changePassword() {
        guard !currentPassword.isEmpty else {
            passwordOK = false
            passwordMessage = "Ingresa tu contraseña actual."
            return
        }
        guard (8...72).contains(newPassword.count) else {
            passwordOK = false
            passwordMessage = "La contraseña nueva debe tener entre 8 y 72 caracteres."
            return
        }
        isSaving = true
        passwordMessage = nil
        Task {
            do {
                try await APIClient.shared.changePassword(current: currentPassword, new: newPassword)
                passwordOK = true
                passwordMessage = "Contraseña actualizada."
                currentPassword = ""
                newPassword = ""
            } catch {
                passwordOK = false
                passwordMessage = error.localizedDescription
            }
            isSaving = false
        }
    }
}
