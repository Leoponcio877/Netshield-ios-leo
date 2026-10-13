import SwiftUI

struct LoginView: View {
    @EnvironmentObject var appState: AppState

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var showRegister = false
    @State private var showForgotPassword = false

    var body: some View {
        NavigationStack {
            ZStack {
                NSTheme.navy.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        VStack(spacing: 8) {
                            Image("logo").resizable().scaledToFit().frame(width: 90, height: 90).clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous)).padding(.top, 40)

                            HStack(spacing: 0) {
                                Text("NET")
                                    .fontWeight(.bold)
                                Text("SHIELD")
                                    .fontWeight(.bold)
                                    .foregroundColor(NSTheme.brandYellow)
                            }
                            .font(.title2)
                            .tracking(2)
                            .foregroundColor(.white)

                            Text("Protege tus datos, reporta el fraude")
                                .font(.subheadline)
                                .foregroundColor(NSTheme.textMuted)
                        }

                        VStack(alignment: .leading, spacing: 20) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Iniciar sesión")
                                    .font(.title2.bold()).foregroundColor(.black)
                                Text("Accede a tu cuenta de forma segura")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Correo electrónico").font(.subheadline.weight(.medium)).foregroundColor(.black)
                                NSTextField(placeholder: "tucorreo@ejemplo.com", text: $email, keyboardType: .emailAddress)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Contraseña").font(.subheadline.weight(.medium)).foregroundColor(.black)
                                NSTextField(placeholder: "••••••••", text: $password, isSecure: true)
                            }

                            if let errorMessage {
                                Text(errorMessage)
                                    .font(.footnote)
                                    .foregroundColor(NSTheme.dangerRed)
                            }

                            HStack {
                                Spacer()
                                Button("¿Olvidaste tu contraseña?") {
                                    showForgotPassword = true
                                }
                                .font(.subheadline)
                                .foregroundColor(NSTheme.navy)
                            }

                            Button(isLoading ? "Ingresando..." : "Iniciar Sesión") {
                                attemptLogin()
                            }
                            .buttonStyle(PrimaryButtonStyle(background: NSTheme.navy, foreground: .white))
                            .disabled(isLoading)

                            HStack {
                                Spacer()
                                Text("¿No tienes cuenta?")
                                    .foregroundColor(.gray)
                                Button("Regístrate aquí") { showRegister = true }
                                    .foregroundColor(.black)
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                            .font(.subheadline)
                        }
                        .padding(24)
                        .background(NSTheme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            .navigationDestination(isPresented: $showRegister) {
                RegisterView()
            }
            .navigationDestination(isPresented: $showForgotPassword) {
                ForgotPasswordView()
            }
        }
    }

    private func attemptLogin() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Ingresa tu correo y contraseña."
            return
        }
        guard email.contains("@") else {
            errorMessage = "Ingresa un correo electrónico válido."
            return
        }
        errorMessage = nil
        isLoading = true
        Task {
            let ok = await appState.login(email: email.trimmingCharacters(in: .whitespaces),
                                          password: password)
            isLoading = false
            if !ok { errorMessage = appState.authError }
        }
    }
}

#Preview {
    LoginView().environmentObject(AppState())
}