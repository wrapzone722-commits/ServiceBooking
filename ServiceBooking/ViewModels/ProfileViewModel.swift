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
    @Published var editPhone = ""
    @Published var editEmail = ""
    @Published var editTelegram = ""
    @Published var editVK = ""
    @Published var editSelectedCarId: String?

    // Список автомобилей для выбора
    @Published private(set) var cars: [Car] = []
    @Published private(set) var isLoadingCars = false

    /// Отображаемое фото авто: задаётся только при выборе автомобиля в профиле, не перезаписывается при загрузке профиля
    @Published private(set) var displayedCarId: String?
    @Published private(set) var displayedCarImageURL: String?

    private static let displayedCarIdKey = "profile_displayed_car_id"
    private static let displayedCarImageURLKey = "profile_displayed_car_image_url"

    init() {
        displayedCarId = UserDefaults.standard.string(forKey: Self.displayedCarIdKey)
        displayedCarImageURL = UserDefaults.standard.string(forKey: Self.displayedCarImageURLKey)
    }

    // MARK: - API Methods
    
    /// Загрузить профиль с сервера
    func loadProfile(silentRefresh: Bool = false) async {
        isLoading = true
        if !silentRefresh {
            errorMessage = nil
        }
        
        do {
            user = try await APIService.shared.fetchProfile()
            syncEditFields()
            // Один раз подхватываем отображаемое авто из профиля (после переустановки или с другого устройства)
            if displayedCarId == nil, let sid = user?.selectedCarId, !sid.isEmpty {
                displayedCarId = sid
                displayedCarImageURL = user?.avatarURL
                saveDisplayedCar()
            }
            if silentRefresh {
                errorMessage = nil // Очищаем ошибку только при успехе
            }
        } catch {
            // При silent refresh не показываем ошибку сразу, даём больше времени
            if !silentRefresh {
                errorMessage = error.localizedDescription
                user = nil
            } else {
                // При pull-to-refresh показываем ошибку только если данных нет совсем
                if user == nil {
                    // Задержка перед показом ошибки при refresh
                    try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 секунды
                    if user == nil {
                        errorMessage = error.localizedDescription
                    }
                }
            }
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
                vk: editVK.isEmpty ? nil : editVK
            )
            
            let request = UpdateProfileRequest(
                firstName: editFirstName,
                lastName: editLastName,
                phone: editPhone.isEmpty ? nil : editPhone,
                email: editEmail.isEmpty ? nil : editEmail,
                selectedCarId: editSelectedCarId,
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
        editPhone = user.isPhoneDisplayable ? user.phone : ""
        editEmail = user.email ?? ""
        editTelegram = user.socialLinks?.telegram ?? ""
        editVK = user.socialLinks?.vk ?? ""
        editSelectedCarId = user.selectedCarId
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
    
    /// Загрузить список автомобилей
    func loadCars() async {
        isLoadingCars = true
        do {
            cars = try await APIService.shared.fetchCars()
        } catch {
            cars = []
        }
        isLoadingCars = false
    }

    /// Выбрать автомобиль и сохранить в профиле. Фото авто становится статичным — меняется только при новом выборе в профиле.
    func selectCar(_ car: Car) async -> Bool {
        guard let u = user else { return false }
        let request = UpdateProfileRequest(
            firstName: u.firstName,
            lastName: u.lastName,
            phone: nil,
            email: u.email,
            selectedCarId: car.id,
            socialLinks: u.socialLinks
        )
        do {
            user = try await APIService.shared.updateProfile(request: request)
            editSelectedCarId = car.id
            displayedCarId = car.id
            displayedCarImageURL = car.imageURL
            saveDisplayedCar()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    private func saveDisplayedCar() {
        UserDefaults.standard.set(displayedCarId, forKey: Self.displayedCarIdKey)
        UserDefaults.standard.set(displayedCarImageURL, forKey: Self.displayedCarImageURLKey)
    }

    /// Очистить данные (выход)
    func clear() {
        user = nil
        isEditing = false
        editSelectedCarId = nil
        displayedCarId = nil
        displayedCarImageURL = nil
        UserDefaults.standard.removeObject(forKey: Self.displayedCarIdKey)
        UserDefaults.standard.removeObject(forKey: Self.displayedCarImageURLKey)
    }
    
    /// Сбросить ошибку (выход с экрана ошибки)
    func clearError() {
        errorMessage = nil
    }
}

enum SocialLinkType {
    case telegram, vk, phone, email
}
