import SwiftUI

/// Lista de países en español, generada por iOS. Se limpian los nombres para que el
/// backend los acepte (solo letras, espacios, punto, apóstrofe y guion; 2 a 60 caracteres).
enum CountryList {
    static let all: [String] = {
        let locale = Locale(identifier: "es_MX")
        let names = Locale.Region.isoRegions
            .filter { $0.subRegions.isEmpty }          // solo países/territorios, no continentes
            .filter { !["EU", "UN", "EZ", "XA", "XB", "ZZ", "QO"].contains($0.identifier) }
            .compactMap { locale.localizedString(forRegionCode: $0.identifier) }
            .map(clean)
            .filter(isValid)
        return Array(Set(names)).sorted { $0.compare($1, locale: locale) == .orderedAscending }
    }()

    private static func clean(_ name: String) -> String {
        var result = name.replacingOccurrences(of: "\\s*\\(.*\\)", with: "", options: .regularExpression)
        result = result.replacingOccurrences(of: "\u{2019}", with: "'")
        return result.trimmingCharacters(in: .whitespaces)
    }

    private static func isValid(_ name: String) -> Bool {
        guard (2...60).contains(name.count) else { return false }
        return name.allSatisfy { $0.isLetter || $0 == " " || $0 == "." || $0 == "'" || $0 == "-" }
    }
}

/// Campo con aspecto de NSTextField que abre una lista con buscador.
struct CountryPickerField: View {
    @Binding var selection: String
    @State private var showSheet = false

    var body: some View {
        Button { showSheet = true } label: {
            HStack {
                Text(selection.isEmpty ? "Selecciona tu país" : selection)
                    .foregroundColor(selection.isEmpty ? .gray : .black)
                Spacer()
                Image(systemName: "chevron.down").foregroundColor(.gray)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showSheet) {
            CountrySheet(selection: $selection)
        }
    }
}

private struct CountrySheet: View {
    @Binding var selection: String
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""

    private var filtered: [String] {
        search.isEmpty ? CountryList.all
            : CountryList.all.filter { $0.range(of: search, options: [.caseInsensitive, .diacriticInsensitive]) != nil }
    }

    var body: some View {
        NavigationStack {
            List(filtered, id: \.self) { country in
                Button {
                    selection = country
                    dismiss()
                } label: {
                    HStack {
                        Text(country).foregroundColor(.primary)
                        Spacer()
                        if country == selection { Image(systemName: "checkmark").foregroundColor(NSTheme.accent) }
                    }
                }
            }
            .searchable(text: $search, prompt: "Buscar país")
            .navigationTitle("País")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cerrar") { dismiss() } }
            }
        }
    }
}
