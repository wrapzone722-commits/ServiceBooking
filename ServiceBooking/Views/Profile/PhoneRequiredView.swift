import SwiftUI

struct PhoneRequiredView: View {
    let initialPhone: String
    let onSave: (_ phone: String) async -> String?
    let onLogout: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var phone: String
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(
        initialPhone: String = "",
        onSave: @escaping (_ phone: String) async -> String?,
        onLogout: @escaping () -> Void
    ) {
        self.initialPhone = initialPhone
        self.onSave = onSave
        self.onLogout = onLogout
        _phone = State(initialValue: initialPhone)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Чтобы мы могли связаться с вами по записи, укажите номер телефона.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    TextField("+7 900 123-45-67", text: $phone)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                } header: {
                    Text("Телефон")
                } footer: {
                    Text("Номер сохранится в профиле и больше не будет запрашиваться.")
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.footnote)
                    }
                }
            }
            .navigationTitle("Укажите телефон")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Выйти") { onLogout() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Сохранение..." : "Сохранить") {
                        Task { await save() }
                    }
                    .disabled(isSaving || cleanedDigits(phone).count < 10)
                }
            }
        }
        .interactiveDismissDisabled(true)
    }

    private func save() async {
        isSaving = true
        errorMessage = nil

        let trimmed = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanedDigits(trimmed).count < 10 {
            errorMessage = "Введите корректный номер"
            isSaving = false
            return
        }

        if let err = await onSave(trimmed) {
            errorMessage = err
            isSaving = false
            return
        }

        isSaving = false
        dismiss()
    }

    private func cleanedDigits(_ s: String) -> String {
        s.replacingOccurrences(of: "\\D", with: "", options: .regularExpression)
    }
}

#Preview {
    PhoneRequiredView(onSave: { _ in nil }, onLogout: {})
}

