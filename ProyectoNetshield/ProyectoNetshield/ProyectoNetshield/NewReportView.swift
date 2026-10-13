import SwiftUI
import PhotosUI

struct NewReportView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var url: String
    @State private var selectedCategory: ReportCategory
    @State private var customCategory = ""
    @State private var descriptionText: String = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var evidenceImage: Image?
    @State private var evidenceData: Data?
    @State private var errorMessage: String?
    @State private var showConfirmation = false
    @State private var isSending = false

    init(prefillURL: String = "", prefillCategory: ReportCategory = .banco) {
        _url = State(initialValue: prefillURL)
        _selectedCategory = State(initialValue: prefillCategory)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                NSTheme.navy.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 20) {

                            VStack(alignment: .leading, spacing: 8) {
                                Text("URL o sitio sospechoso").font(.subheadline.weight(.semibold)).foregroundColor(.black)
                                HStack {
                                    Image(systemName: "link")
                                        .foregroundColor(.gray)
                                    TextField("", text: $url).foregroundColor(.black)
                                        .autocapitalization(.none)
                                        .disableAutocorrection(true)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                                Text("Ej: https://banco-falso.com · http://sorteo-premio.xyz")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }

                            VStack(alignment: .leading, spacing: 10) {
                                Text("Subcategoría").font(.subheadline.weight(.semibold)).foregroundColor(.black)
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                    ForEach(ReportCategory.allCases) { category in
                                        CategoryChip(category: category, isSelected: selectedCategory == category) {
                                            selectedCategory = category
                                        }
                                    }
                                }
                                if selectedCategory == .otro {
                                    NSTextField(placeholder: "Escribe la categoría (ej. Servicios de paquetería)",
                                                text: $customCategory)
                                }
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Evidencia").font(.subheadline.weight(.semibold)).foregroundColor(.black)
                                Text("Capturas de pantalla del sitio sospechoso")
                                    .font(.caption)
                                    .foregroundColor(.gray)

                                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(Color.white.opacity(0.6))
                                            .frame(height: 160)
                                        if let evidenceImage {
                                            evidenceImage
                                                .resizable()
                                                .scaledToFill()
                                                .frame(height: 160)
                                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                        } else {
                                            VStack(spacing: 8) {
                                                Image(systemName: "photo.badge.plus")
                                                    .font(.system(size: 30))
                                                    .foregroundColor(.gray)
                                                Text("Toca para agregar una imagen")
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                            }
                                        }
                                    }
                                }
                                .onChange(of: selectedPhoto) { _, newItem in
                                    Task { await loadImage(from: newItem) }
                                }
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Describe brevemente qué pasó").font(.subheadline.weight(.semibold)).foregroundColor(.black)
                                TextEditor(text: $descriptionText).foregroundColor(.black)
                                    .frame(height: 100)
                                    .padding(8).scrollContentBackground(.hidden)
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }

                            if let errorMessage {
                                Text(errorMessage)
                                    .font(.footnote)
                                    .foregroundColor(NSTheme.dangerRed)
                            }
                        }
                        .padding(20)
                        .background(NSTheme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

                        Button {
                            submit()
                        } label: {
                            HStack {
                                Image(systemName: "checkmark.seal.fill")
                                Text(isSending ? "Enviando..." : "Enviar reporte")
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(isSending)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Nuevo reporte")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                    }
                }
            }
            .alert("¡Gracias por tu reporte!", isPresented: $showConfirmation) {
                Button("Listo") { dismiss() }
            } message: {
                Text("Tu reporte fue enviado y quedará en revisión por el equipo de NetShield.")
            }
        }
    }

    private func loadImage(from item: PhotosPickerItem?) async {
        guard let item,
              let data = try? await item.loadTransferable(type: Data.self),
              let uiImage = UIImage(data: data) else { return }
        let scale = min(1, 1600 / max(uiImage.size.width, uiImage.size.height))
        let size = CGSize(width: uiImage.size.width * scale, height: uiImage.size.height * scale)
        let resized = UIGraphicsImageRenderer(size: size).image { _ in uiImage.draw(in: CGRect(origin: .zero, size: size)) }
        evidenceImage = Image(uiImage: resized)
        evidenceData = resized.jpegData(compressionQuality: 0.7)
    }

    private func submit() {
        guard !isSending else { return }
        guard !url.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Ingresa la URL o sitio sospechoso."
            return
        }
        guard !descriptionText.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Describe brevemente qué pasó."
            return
        }
        let custom = customCategory.trimmingCharacters(in: .whitespaces)
        if selectedCategory == .otro && !(3...40).contains(custom.count) {
            errorMessage = "Escribe la categoría (entre 3 y 40 caracteres)."
            return
        }
        errorMessage = nil
        isSending = true
        Task {
            let ok = await appState.submitReport(url: url.trimmingCharacters(in: .whitespaces),
                                                 category: selectedCategory,
                                                 customName: selectedCategory == .otro ? custom : nil,
                                                 description: descriptionText,
                                                 evidence: evidenceData)
            isSending = false
            if ok { showConfirmation = true } else { errorMessage = appState.authError }
        }
    }
}

struct CategoryChip: View {
    let category: ReportCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: category.icon)
                Text(category.rawValue)
                    .fontWeight(.semibold)
            }
            .font(.subheadline)
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? category.tintColor.opacity(0.35) : category.tintColor.opacity(0.15))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? category.tintColor : .clear, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}

#Preview {
    NewReportView().environmentObject(AppState())
}