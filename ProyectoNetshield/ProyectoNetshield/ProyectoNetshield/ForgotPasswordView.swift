import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.dismiss) var dismiss
    @State private var email: String = ""
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            NSTheme.navy.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    VStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(NSTheme.accent, lineWidth: 3)
                                .frame(width: 90, height: 90)
                            Image(systemName: "lock.rotation")
                                .font(.system(size: 40))
                                .foregroundStyle(.white, NSTheme.accent)
                        }
                        .padding(.top, 40)

                        Text("Recuperar contraseña")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 20) {
                        Text("Ingresa tu correo para solicitar el restablecimiento de tu contraseña.")
                            .font(.subheadline)
                            .foregroundColor(.gray)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Correo electrónico").font(.subheadline.weight(.medium)).foregroundColor(.black)
                            NSTextField(placeholder: "tucorreo@ejemplo.com", text: $email, keyboardType: .emailAddress)
                        }

                        if let errorMessage {
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundColor(NSTheme.dangerRed)
                        }

                        Button("Enviar instrucciones") {
                            attemptRecovery()
                        }
                        .buttonStyle(PrimaryButtonStyle(background: NSTheme.navy, foreground: .white))
                    }
                    .padding(24)
                    .background(NSTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }

    // TODO: endpoint pendiente (recuperación de contraseña). Hasta entonces no se promete un correo.
    private func attemptRecovery() {
        guard !email.isEmpty, email.contains("@") else {
            errorMessage = "Ingresa un correo electrónico válido."
            return
        }
        errorMessage = "Función no disponible por ahora. Contacta al administrador de NetShield."
    }
}

#Preview {
    NavigationStack {
        ForgotPasswordView()
    }
}