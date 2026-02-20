//
//  MyContactsView.swift
//  ServiceBooking
//
//  Экран "Мои контакты"
//

import SwiftUI

struct MyContactsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: ProfileViewModel
    @State private var editing: ContactField?
    @State private var draft = ""
    @State private var saving = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Описание
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Ваши контакты")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Здесь отображаются все ваши контактные данные, которые используются для связи с вами.")
                            .font(.subheadline)
                            .foregroundStyle(Color(.secondaryLabel))
                    }
                    .padding(.horizontal)
                    
                    // Список контактов
                    VStack(spacing: 16) {
                        contactCardButton(
                            icon: "paperplane.fill",
                            title: "Telegram",
                            value: telegramValue,
                            placeholder: "Добавить",
                            color: .blue
                        ) { beginEdit(.telegram) }
                        
                        contactCardButton(
                            icon: "person.2.fill",
                            title: "VK",
                            value: vkValue,
                            placeholder: "Добавить",
                            color: .blue
                        ) { beginEdit(.vk) }
                        
                        contactCardButton(
                            icon: "envelope.fill",
                            title: "Email",
                            value: emailValue,
                            placeholder: "Добавить",
                            color: .gray
                        ) { beginEdit(.email) }
                        
                        contactCardButton(
                            icon: "phone.fill",
                            title: "Телефон",
                            value: phoneValue,
                            placeholder: "Добавить",
                            color: .green
                        ) { beginEdit(.phone) }
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 40)
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Мои контакты")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") { dismiss() }
                }
            }
            .sheet(item: $editing) { field in
                editSheet(for: field)
            }
        }
    }
    
    private var telegramValue: String? {
        let v = viewModel.user?.socialLinks?.telegram?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return v.isEmpty ? nil : v
    }

    private var vkValue: String? {
        let v = viewModel.user?.socialLinks?.vk?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return v.isEmpty ? nil : v
    }

    private var emailValue: String? {
        let v = viewModel.user?.email?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return v.isEmpty ? nil : v
    }

    private var phoneValue: String? {
        guard let u = viewModel.user, u.isPhoneDisplayable else { return nil }
        let v = u.phone.trimmingCharacters(in: .whitespacesAndNewlines)
        return v.isEmpty ? nil : v
    }

    private func contactCardButton(
        icon: String,
        title: String,
        value: String?,
        placeholder: String,
        color: Color,
        onTap: @escaping () -> Void
    ) -> some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(color.opacity(0.15))
                        .frame(width: 56, height: 56)
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color(.label))
                    if let value = value, !value.isEmpty {
                        Text(value)
                            .font(.caption)
                            .foregroundStyle(Color(.secondaryLabel))
                            .lineLimit(1)
                    } else {
                        Text(placeholder)
                            .font(.caption)
                            .foregroundStyle(Color(.tertiaryLabel))
                    }
                }

                Spacer()

                Text(value == nil ? "Добавить" : "Изменить")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.accentColor)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color(.tertiaryLabel))
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    private func beginEdit(_ field: ContactField) {
        errorMessage = nil
        saving = false
        switch field {
        case .telegram:
            draft = viewModel.user?.socialLinks?.telegram ?? ""
        case .vk:
            draft = viewModel.user?.socialLinks?.vk ?? ""
        case .email:
            draft = viewModel.user?.email ?? ""
        case .phone:
            draft = (viewModel.user?.isPhoneDisplayable ?? false) ? (viewModel.user?.phone ?? "") : ""
        }
        editing = field
    }

    @ViewBuilder
    private func editSheet(for field: ContactField) -> some View {
        NavigationStack {
            Form {
                Section {
                    TextField(field.placeholder, text: $draft)
                        .textInputAutocapitalization(field.autocapitalization)
                        .keyboardType(field.keyboard)
                        .autocorrectionDisabled()
                } footer: {
                    Text(field.hint)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.footnote)
                    }
                }
            }
            .navigationTitle(field.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { editing = nil }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(saving ? "Сохранение..." : "Сохранить") {
                        Task { await save(field: field) }
                    }
                    .disabled(saving)
                }
            }
        }
    }

    private func save(field: ContactField) async {
        saving = true
        errorMessage = nil

        let cleaned = field.clean(draft)
        viewModel.syncEditFields()

        switch field {
        case .telegram:
            viewModel.editTelegram = cleaned
        case .vk:
            viewModel.editVK = cleaned
        case .email:
            viewModel.editEmail = cleaned
        case .phone:
            viewModel.editPhone = cleaned
        }

        let ok = await viewModel.saveProfile()
        saving = false

        if ok {
            editing = nil
        } else {
            errorMessage = viewModel.errorMessage ?? "Не удалось сохранить"
        }
    }
}

private enum ContactField: String, Identifiable {
    case telegram, vk, email, phone
    var id: String { rawValue }

    var title: String {
        switch self {
        case .telegram: return "Telegram"
        case .vk: return "VK"
        case .email: return "Email"
        case .phone: return "Телефон"
        }
    }

    var placeholder: String {
        switch self {
        case .telegram: return "@username"
        case .vk: return "vk.com/username"
        case .email: return "name@example.com"
        case .phone: return "+7 900 123-45-67"
        }
    }

    var hint: String {
        switch self {
        case .telegram:
            return "Можно указать @username или ссылку — мы сохраним в удобном формате. Чтобы получать уведомления, откройте бота и нажмите Start (/start)."
        case .vk:
            return "Можно вставить ссылку или короткое имя (например, id123 или username)."
        case .email:
            return "Используется для связи и уведомлений."
        case .phone:
            return "Номер телефона для связи. Можно указать с +7."
        }
    }

    var keyboard: UIKeyboardType {
        switch self {
        case .email: return .emailAddress
        case .phone: return .phonePad
        default: return .default
        }
    }

    var autocapitalization: TextInputAutocapitalization? {
        switch self {
        case .email, .telegram, .vk: return .never
        case .phone: return .never
        }
    }

    func clean(_ raw: String) -> String {
        let s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else { return "" }
        switch self {
        case .telegram:
            // @user, https://t.me/user, t.me/user → user
            var out = s
                .replacingOccurrences(of: "https://", with: "")
                .replacingOccurrences(of: "http://", with: "")
            if out.hasPrefix("t.me/") { out = String(out.dropFirst(5)) }
            if out.hasPrefix("@") { out = String(out.dropFirst()) }
            return out.trimmingCharacters(in: CharacterSet(charactersIn: "/")).trimmingCharacters(in: .whitespaces)
        case .vk:
            // https://vk.com/user → user
            var out = s
                .replacingOccurrences(of: "https://", with: "")
                .replacingOccurrences(of: "http://", with: "")
            if out.hasPrefix("vk.com/") { out = String(out.dropFirst(7)) }
            return out.trimmingCharacters(in: CharacterSet(charactersIn: "/")).trimmingCharacters(in: .whitespaces)
        case .email:
            return s.lowercased()
        case .phone:
            return s
        }
    }
}

#Preview {
    MyContactsView()
        .environmentObject(ProfileViewModel())
}
