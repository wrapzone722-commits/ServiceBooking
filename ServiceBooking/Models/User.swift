//
//  User.swift
//  ServiceBooking
//
//  Модель пользователя (данные приходят с сервера)
//

import Foundation

/// Уровень в программе лояльности
enum ClientTier: String, Codable, CaseIterable {
    case client
    case regular
    case pride

    var displayName: String {
        switch self {
        case .client: return "Клиент"
        case .regular: return "Постоянный клиент"
        case .pride: return "Прайд"
        }
    }
}

/// Модель пользователя
struct User: Identifiable, Codable {
    let id: String
    var firstName: String
    var lastName: String
    var phone: String
    var email: String?
    var avatarURL: String?
    var selectedCarId: String?
    var socialLinks: SocialLinks?
    let createdAt: Date
    /// Накопительные баллы (с сервера)
    var loyaltyPoints: Int
    /// Уровень в программе лояльности
    var clientTier: ClientTier
    /// Имя файла фото авто по правилу (01/02/03/04) — после посещения 01, далее по настройкам консоли
    var displayPhotoName: String

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case firstName = "first_name"
        case lastName = "last_name"
        case phone
        case email
        case avatarURL = "avatar_url"
        case selectedCarId = "selected_car_id"
        case socialLinks = "social_links"
        case createdAt = "created_at"
        case loyaltyPoints = "loyalty_points"
        case clientTier = "client_tier"
        case isVip = "is_vip"
        case displayPhotoName = "display_photo_name"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        firstName = try c.decode(String.self, forKey: .firstName)
        lastName = try c.decode(String.self, forKey: .lastName)
        phone = try c.decode(String.self, forKey: .phone)
        email = try c.decodeIfPresent(String.self, forKey: .email)
        avatarURL = try c.decodeIfPresent(String.self, forKey: .avatarURL)
        selectedCarId = try c.decodeIfPresent(String.self, forKey: .selectedCarId)
        socialLinks = try c.decodeIfPresent(SocialLinks.self, forKey: .socialLinks)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        loyaltyPoints = try c.decodeIfPresent(Int.self, forKey: .loyaltyPoints) ?? 0
        if let tier = try c.decodeIfPresent(ClientTier.self, forKey: .clientTier) {
            clientTier = tier
        } else if (try c.decodeIfPresent(Bool.self, forKey: .isVip)) == true {
            clientTier = .pride
        } else {
            clientTier = .client
        }
        displayPhotoName = try c.decodeIfPresent(String.self, forKey: .displayPhotoName) ?? "01"
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(firstName, forKey: .firstName)
        try c.encode(lastName, forKey: .lastName)
        try c.encode(phone, forKey: .phone)
        try c.encodeIfPresent(email, forKey: .email)
        try c.encodeIfPresent(avatarURL, forKey: .avatarURL)
        try c.encodeIfPresent(selectedCarId, forKey: .selectedCarId)
        try c.encodeIfPresent(socialLinks, forKey: .socialLinks)
        try c.encode(createdAt, forKey: .createdAt)
        try c.encode(loyaltyPoints, forKey: .loyaltyPoints)
        try c.encode(clientTier, forKey: .clientTier)
        try c.encode(displayPhotoName, forKey: .displayPhotoName)
    }

    init(id: String, firstName: String, lastName: String, phone: String, email: String?, avatarURL: String?, selectedCarId: String?, socialLinks: SocialLinks?, createdAt: Date, loyaltyPoints: Int = 0, clientTier: ClientTier = .client, displayPhotoName: String = "01") {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.phone = phone
        self.email = email
        self.avatarURL = avatarURL
        self.selectedCarId = selectedCarId
        self.socialLinks = socialLinks
        self.createdAt = createdAt
        self.loyaltyPoints = loyaltyPoints
        self.clientTier = clientTier
        self.displayPhotoName = displayPhotoName
    }

    var fullName: String { "\(firstName) \(lastName)" }
    
    /// Имя для отображения в профиле: без технического идентификатора в фамилии (например «Клиент F72E5F» → «Клиент»).
    var displayNameForProfile: String {
        let trimmedFirst = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLast = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        let lastLooksLikeId = trimmedLast.range(of: #"^[A-Fa-f0-9]{6,}$"#, options: .regularExpression) != nil
            || trimmedLast.lowercased().hasPrefix("device:")
            || trimmedLast == id
        if lastLooksLikeId {
            return trimmedFirst.isEmpty ? "Имя не указано" : trimmedFirst
        }
        if trimmedFirst.isEmpty && trimmedLast.isEmpty { return "Имя не указано" }
        return "\(trimmedFirst) \(trimmedLast)".trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Телефон показывать только если это не технический идентификатор (например не «device:...»).
    var isPhoneDisplayable: Bool {
        let p = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !p.isEmpty else { return false }
        return !p.lowercased().hasPrefix("device:")
    }
    
    var initials: String {
        let f = firstName.first.map { String($0) } ?? ""
        let l = lastName.first.map { String($0) } ?? ""
        return "\(f)\(l)".uppercased()
    }

    // MARK: - Profile Completeness (для подсказок)

    /// Полнота профиля для ненавязчивых подсказок
    var profileCompleteness: ProfileCompleteness {
        let hasName = displayNameForProfile != "Имя не указано"
        let hasCar = selectedCarId != nil && !(selectedCarId?.isEmpty ?? true)
        let hasSocial = (socialLinks?.telegram).map { !$0.trimmingCharacters(in: .whitespaces).isEmpty } ?? false
            || (socialLinks?.vk).map { !$0.trimmingCharacters(in: .whitespaces).isEmpty } ?? false

        var missing: [ProfileMissingItem] = []
        if !hasName { missing.append(.name) }
        if !hasCar { missing.append(.car) }
        if !hasSocial { missing.append(.socialLinks) }

        let filled = (hasName ? 1 : 0) + (hasCar ? 1 : 0) + (hasSocial ? 1 : 0)
        let progress = min(100, (filled * 100) / 3)

        return ProfileCompleteness(
            isComplete: missing.isEmpty,
            progress: progress,
            missingItems: missing,
            primarySuggestion: missing.first
        )
    }
}

/// Элементы профиля для подсказок
enum ProfileMissingItem: String {
    case name
    case car
    case socialLinks

    var title: String {
        switch self {
        case .name: return "Имя"
        case .car: return "Тип автомобиля"
        case .socialLinks: return "Соцсети (Telegram/VK)"
        }
    }

    var hint: String {
        switch self {
        case .name: return "Укажите имя — так мы будем обращаться к вам"
        case .car: return "Нажмите на фото выше и выберите тип авто"
        case .socialLinks: return "Добавьте Telegram или VK — для уведомлений о записях"
        }
    }

    var icon: String {
        switch self {
        case .name: return "person.fill"
        case .car: return "car.fill"
        case .socialLinks: return "paperplane.fill"
        }
    }
}

/// Результат оценки полноты профиля
struct ProfileCompleteness {
    let isComplete: Bool
    let progress: Int
    let missingItems: [ProfileMissingItem]
    let primarySuggestion: ProfileMissingItem?

    var suggestionTitle: String {
        guard let p = primarySuggestion else { return "" }
        return p.hint
    }
}

/// Социальные сети (Telegram, VK / Макс)
struct SocialLinks: Codable, Hashable {
    var telegram: String?
    var vk: String?
    
    var hasAnyLink: Bool {
        telegram != nil || vk != nil
    }
}

/// Запрос обновления профиля
struct UpdateProfileRequest: Codable {
    let firstName: String?
    let lastName: String?
    let email: String?
    let selectedCarId: String?
    let socialLinks: SocialLinks?

    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case lastName = "last_name"
        case email
        case selectedCarId = "selected_car_id"
        case socialLinks = "social_links"
    }
}

// MARK: - Preview Data
#if DEBUG
extension User {
    static let preview = User(
        id: "demo",
        firstName: "Александр",
        lastName: "Иванов",
        phone: "+7 (999) 123-45-67",
        email: "alex@example.com",
        avatarURL: nil,
        selectedCarId: nil,
        socialLinks: SocialLinks(telegram: "@alex", vk: "alexivanov"),
        createdAt: Date(),
        loyaltyPoints: 350,
        clientTier: .regular,
        displayPhotoName: "01"
    )
}
#endif
