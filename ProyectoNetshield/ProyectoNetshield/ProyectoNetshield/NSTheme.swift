import SwiftUI

enum NSTheme {
    static let navy = Color(red: 0.043, green: 0.122, blue: 0.227)          // #0b1f3a
    static let navyLight = Color(red: 0.075, green: 0.176, blue: 0.322)     // #132d52
    static let cardBackground = Color(red: 0.945, green: 0.961, blue: 0.976) // #f1f5f9
    static let accent = Color(red: 0.220, green: 0.741, blue: 0.973)        // #38bdf8
    static let brandYellow = Color(red: 0.973, green: 0.686, blue: 0.188)   // #facc15
    static let warning = Color(red: 0.961, green: 0.620, blue: 0.043)       // #f59e0b
    static let dangerRed = Color(red: 0.937, green: 0.267, blue: 0.267)     // #ef4444
    static let safeGreen = Color(red: 0.133, green: 0.773, blue: 0.369)     // #22c55e
    static let textMuted = Color(red: 0.580, green: 0.639, blue: 0.722)     // #94a3b8
}

// Botón primario reutilizable
struct PrimaryButtonStyle: ButtonStyle {
    var background: Color = NSTheme.accent
    var foreground: Color = NSTheme.navy

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(foreground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .opacity(configuration.isPressed ? 0.8 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

// Chip de filtro reutilizable
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(isSelected ? NSTheme.navy : .white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(isSelected ? NSTheme.brandYellow : NSTheme.navyLight)
                .clipShape(Capsule())
        }
    }
}

// Campo de texto con estilo de la app. Si es de contraseña, muestra el "ojito" para verla.
struct NSTextField: View {
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default

    @State private var isRevealed = false

    var body: some View {
        HStack(spacing: 8) {
            Group {
                if isSecure && !isRevealed {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboardType)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
            }
            .foregroundColor(.black)

            if isSecure {
                Button {
                    isRevealed.toggle()
                } label: {
                    Image(systemName: isRevealed ? "eye.slash.fill" : "eye.fill")
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isRevealed ? "Ocultar contraseña" : "Mostrar contraseña")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
