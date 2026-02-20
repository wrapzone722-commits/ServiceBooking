import SwiftUI

/// Обязательное заполнение профиля перед созданием записи.
/// Требуем: имя, телефон, автомобиль.
struct BookingProfileRequiredView: View {
    let onCompleted: () -> Void
    let onCancel: () -> Void

    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @State private var isSaving = false
    @State private var localError: String?

    @FocusState private var focusedField: Field?

    enum Field {
        case firstName, phone
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Имя", text: $profileViewModel.editFirstName)
                        .textContentType(.givenName)
                        .focused($focusedField, equals: .firstName)

                    TextField("+7 900 123-45-67", text: $profileViewModel.editPhone)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                        .focused($focusedField, equals: .phone)
                } header: {
                    Text("Контакты")
                } footer: {
                    Text("Имя и телефон нужны, чтобы подтвердить запись и связаться с вами.")
                }

                Section {
                    if profileViewModel.isLoadingCars {
                        HStack {
                            ProgressView()
                            Text("Загружаем автомобили…")
                                .foregroundStyle(.secondary)
                        }
                    } else if profileViewModel.cars.isEmpty {
                        Button("Загрузить список автомобилей") {
                            Task { await profileViewModel.loadCars() }
                        }
                    } else {
                        Picker("Автомобиль", selection: Binding(
                            get: { profileViewModel.editSelectedCarId ?? "" },
                            set: { profileViewModel.editSelectedCarId = $0.isEmpty ? nil : $0 }
                        )) {
                            Text("Выберите…").tag("")
                            ForEach(profileViewModel.cars) { car in
                                Text(car.name).tag(car.id)
                            }
                        }
                    }
                } header: {
                    Text("Автомобиль")
                } footer: {
                    Text("Выберите тип автомобиля — это поможет нам подготовиться к услуге.")
                }

                if let msg = localError ?? profileViewModel.errorMessage {
                    Section {
                        Text(msg)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Заполните профиль")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { onCancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Сохранение..." : "Сохранить") {
                        Task { await save() }
                    }
                    .disabled(isSaving || !isValid)
                }
            }
            .onAppear {
                if profileViewModel.user == nil {
                    Task { await profileViewModel.loadProfile(silentRefresh: true) }
                }
                if profileViewModel.cars.isEmpty {
                    Task { await profileViewModel.loadCars() }
                }
                if profileViewModel.editFirstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    focusedField = .firstName
                } else if cleanedDigits(profileViewModel.editPhone).count < 10 {
                    focusedField = .phone
                }
            }
        }
        .interactiveDismissDisabled(true)
    }

    private var isValid: Bool {
        let firstNameOk = !profileViewModel.editFirstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let phoneOk = cleanedDigits(profileViewModel.editPhone).count >= 10
        let carOk = !(profileViewModel.editSelectedCarId?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        return firstNameOk && phoneOk && carOk
    }

    private func save() async {
        localError = nil
        isSaving = true

        if !isValid {
            localError = "Заполните имя, телефон и автомобиль"
            isSaving = false
            return
        }

        let ok = await profileViewModel.saveProfile()
        isSaving = false

        if ok {
            onCompleted()
        } else if localError == nil {
            localError = profileViewModel.errorMessage ?? "Не удалось сохранить профиль"
        }
    }

    private func cleanedDigits(_ s: String) -> String {
        s.replacingOccurrences(of: "\\D", with: "", options: .regularExpression)
    }
}

#Preview {
    BookingProfileRequiredView(onCompleted: {}, onCancel: {})
        .environmentObject(ProfileViewModel())
}

