//
//  User.swift
//  ServiceBooking
//
//  Модель пользователя (данные приходят с сервера)
//

import Foundation

/// Модель пользователя
struct User: Identifiable, Codable {
    let id: String
    var firstName: String
    var lastName: String
    var phone: String
    var email: String?
    var avatarURL: String?
    var socialLinks: SocialLinks?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case firstName = "first_name"
        case lastName = "last_name"
        case phone
        case email
        case avatarURL = "avatar_url"
        case socialLinks = "social_links"
        case createdAt = "created_at"
    }
    
    var fullName: String { "\(firstName) \(lastName)" }
    
    var initials: String {
        let f = firstName.first.map { String($0) } ?? ""
        let l = lastName.first.map { String($0) } ?? ""
        return "\(f)\(l)".uppercased()
    }
}

/// Социальные сети
struct SocialLinks: Codable, Hashable {
    var telegram: String?
    var whatsapp: String?
    var instagram: String?
    var vk: String?
    
    var hasAnyLink: Bool {
        telegram != nil || whatsapp != nil || instagram != nil || vk != nil
    }
}

/// Запрос обновления профиля
struct UpdateProfileRequest: Codable {
    let firstName: String?
    let lastName: String?
    let email: String?
    let socialLinks: SocialLinks?
    
    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case lastName = "last_name"
        case email
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
        socialLinks: SocialLinks(telegram: "@alex", whatsapp: "+79991234567", instagram: "alex.ivanov", vk: "alexivanov"),
        createdAt: Date()
    )
}
#endif
