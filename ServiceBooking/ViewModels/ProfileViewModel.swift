//
//  ProfileViewModel.swift
//  ServiceBooking
//
//  ViewModel для профиля
//  Данные загружаются с сервера, НЕ хранятся локально
//

import Foundation
import SwiftUI

@MainActor
class ProfileViewModel: ObservableObject {
    
    // Данные профиля (в памяти)
    @Published private(set) var user: User?
    
    // Состояние
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    @Published var isEditing = false
    
    // Редактируемые поля (временные)
    @Published var editFirstName = ""
    @Published var editLastName = ""
    @Published var editEmail = ""
    @Published var editTelegram = ""
    @Published var editWhatsApp = ""
    @Published var editInstagram = ""
    @Published var editVK = ""
    
    // MARK: - API Methods
    
    /// Загрузить профиль с сервера
    func loadProfile() async {
        isLoading = true
        errorMessage = nil
        
        do {
            user = try await APIService.shared.fetchProfile()
            syncEditFields()
        } catch {
            errorMessage = error.localizedDescription
            user = nil
        }
        
        isLoading = false
    }
    
    /// Сохранить изменения на сервер
    func saveProfile() async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let socialLinks = SocialLinks(
                telegram: editTelegram.isEmpty ? nil : editTelegram,
                whatsapp: editWhatsApp.isEmpty ? nil : editWhatsApp,
                instagram: editInstagram.isEmpty ? nil : editInstagram,
                vk: editVK.isEmpty ? nil : editVK
            )
            
            let request = UpdateProfileRequest(
                firstName: editFirstName,
                lastName: editLastName,
                email: editEmail.isEmpty ? nil : editEmail,
                socialLinks: socialLinks
            )
            
            // Отправляем на сервер и получаем обновленные данные
            user = try await APIService.shared.updateProfile(request: request)
            
            withAnimation { isEditing = false }
            isLoading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
    
    // MARK: - Editing
    
    func syncEditFields() {
        guard let user = user else { return }
        editFirstName = user.firstName
        editLastName = user.lastName
        editEmail = user.email ?? ""
        editTelegram = user.socialLinks?.telegram ?? ""
        editWhatsApp = user.socialLinks?.whatsapp ?? ""
        editInstagram = user.socialLinks?.instagram ?? ""
        editVK = user.socialLinks?.vk ?? ""
    }
    
    func startEditing() {
        syncEditFields()
        withAnimation { isEditing = true }
    }
    
    func cancelEditing() {
        syncEditFields()
        withAnimation { isEditing = false }
    }
    
    // MARK: - Social Links
    
    func openSocialLink(_ type: SocialLinkType) {
        guard let user = user else { return }
        
        var urlString: String?
        
        switch type {
        case .telegram:
            if let t = user.socialLinks?.telegram {
                urlString = "https://t.me/\(t.replacingOccurrences(of: "@", with: ""))"
            }
        case .whatsapp:
            if let w = user.socialLinks?.whatsapp {
                let clean = w.replacingOccurrences(of: "+", with: "")
                    .replacingOccurrences(of: " ", with: "")
                    .replacingOccurrences(of: "-", with: "")
                urlString = "https://wa.me/\(clean)"
            }
        case .instagram:
            if let i = user.socialLinks?.instagram {
                urlString = "https://instagram.com/\(i)"
            }
        case .vk:
            if let v = user.socialLinks?.vk {
                urlString = "https://vk.com/\(v)"
            }
        case .phone:
            let clean = user.phone.replacingOccurrences(of: " ", with: "")
                .replacingOccurrences(of: "(", with: "")
                .replacingOccurrences(of: ")", with: "")
                .replacingOccurrences(of: "-", with: "")
            urlString = "tel:\(clean)"
        case .email:
            if let e = user.email { urlString = "mailto:\(e)" }
        }
        
        if let urlString = urlString, let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
    
    /// Очистить данные (выход)
    func clear() {
        user = nil
        isEditing = false
    }
    
    /// Сбросить ошибку (выход с экрана ошибки)
    func clearError() {
        errorMessage = nil
    }
}

enum SocialLinkType {
    case telegram, whatsapp, instagram, vk, phone, email
}
