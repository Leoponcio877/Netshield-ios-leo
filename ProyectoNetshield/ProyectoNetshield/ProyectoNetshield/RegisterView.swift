import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var username: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var country: String = ""
    @State private var errorMessage: String?
    @State private var isLoading = false

    var body: some View {
        ZStack {
            NSTheme.navy.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    VStack(spacing: 8) {
                        Image("logo").resizable().scaledToFit().frame(width: 90, height: 90).clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous)).padding(.top, 40)

                        HStack(spacing: 0) {
                            Text("NET").fontWeight(.bold)
                            Text("SHIELD").fontWeight(.bold).foregroundColor(NSTheme.brandYellow)
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
                            Text("Crear cuenta").font(.title2.bold()).foregroundColor(.black)
                            Text("Nueva cuenta de usuario")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }

                        labeledField("Usuario", text: $username)
                        labeledField("Correo Electrónico", text: $email, keyboardType: .emailAddress)
                        labeledField("Contraseña", text: $password, isSecure: true)
                        labeledField("Confirmar contraseña", text: $confirmPassword, isSecure: true)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("País").font(.subheadline.weight(.medium)).foregroundColor(.black)
                            CountryPickerField(selection: $country)
                        }

                        if let errorMessage {
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundColor(NSTheme.dangerRed)
                        }

                        Button(isLoading ? "Registrando..." : "Registrar") { attemptRegister() }
                            .disabled(isLoading)
                            .buttonStyle(PrimaryButtonStyle(background: NSTheme.navy, foreground: .white))

                        HStack {
                            Spacer()
                            Text("¿Ya tienes una cuenta?").foregroundColor(.gray)
                            Button("Inicia Sesión") { dismiss() }
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
        .toolbar(.hidden, for: .navigationBar)
    }

    @ViewBuilder
    private func labeledField(_ title: String, text: Binding<String>, isSecure: Bool = false, keyboardType: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.subheadline.weight(.medium)).foregroundColor(.black)
            NSTextField(placeholder: title, text: text, isSecure: isSecure, keyboardType: keyboardType)
        }
    }

    private func attemptRegister() {
        guard !username.isEmpty, !email.isEmpty, !password.isEmpty, !confirmPassword.isEmpty, !country.isEmpty else {
            errorMessage = "Completa todos los campos."
            return
        }
        guard email.contains("@") else {
            errorMessage = "Ingresa un correo electrónico válido."
            return
        }
        guard password.count >= 8 else {
            errorMessage = "La contraseña debe tener al menos 8 caracteres."
            return
        }
        guard password == confirmPassword else {
            errorMessage = "Las contraseñas no coinciden."
            return
        }
        errorMessage = nil
        isLoading = true
        Task {
            let ok = await appState.register(username: username,
                                             email: email.trimmingCharacters(in: .whitespaces),
                                             password: password,
                                             country: country)
            isLoading = false
            if ok {
                dismiss()   // regresa a LoginView
            } else {
                errorMessage = appState.authError
            }
        }
    }
}

#Preview {
    RegisterView().environmentObject(AppState())
}

