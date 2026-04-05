//
//  PushNotificationService.swift
//  ServiceBooking
//
//  Регистрация push-уведомлений, отправка device token на сервер, учёт настройки «Push-уведомления».
//

import Foundation
import UIKit
import UserNotifications

/// Сервис push-уведомлений: разрешения, регистрация в APNs, отправка токена на бэкенд
final class PushNotificationService {
    static let shared = PushNotificationService()
    
    private init() {}
    
    /// Включены ли push в настройках приложения (без учёта системного разрешения).
    /// По умолчанию true, чтобы совпадать с переключателем в профиле.
    var isPushEnabledInSettings: Bool {
        (UserDefaults.standard.object(forKey: ProfileSettingsKeys.pushEnabled) as? Bool) ?? true
    }
    
    /// Запросить разрешение у пользователя и зарегистрировать для remote notifications.
    /// Вызывать, когда пользователь включил «Push-уведомления» в настройках профиля.
    func requestPermissionAndRegisterIfNeeded() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, _ in
            DispatchQueue.main.async {
                if granted {
                    self?.registerForRemoteNotifications()
                }
            }
        }
    }
    
    /// Зарегистрировать приложение в APNs (вызов после разрешения или при запуске, если уже разрешено).
    func registerForRemoteNotifications() {
        guard isPushEnabledInSettings else { return }
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    
    /// Снять регистрацию remote notifications (при отключении push в настройках).
    func unregisterForRemoteNotifications() {
        DispatchQueue.main.async {
            UIApplication.shared.unregisterForRemoteNotifications()
        }
    }
    
    /// Вызывается из AppDelegate при получении device token от APNs.
    func didRegisterForRemoteNotifications(deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        Task {
            await sendTokenToServer(tokenString)
        }
    }
    
    /// Вызывается из AppDelegate при ошибке регистрации (например, симулятор).
    func didFailToRegisterForRemoteNotifications(error: Error) {
        // В симуляторе push не поддерживаются — это нормально
        #if DEBUG
        print("[Push] Failed to register: \(error.localizedDescription)")
        #endif
    }
    
    /// Отправить APNs token на бэкенд (PUT /profile с push_token).
    private func sendTokenToServer(_ token: String) async {
        guard !token.isEmpty, ConsoleConfigStorage.shared.hasConfig else { return }
        do {
            try await APIService.shared.registerPushToken(token)
        } catch {
            #if DEBUG
            print("[Push] Failed to send token: \(error.localizedDescription)")
            #endif
        }
    }
    
    /// Очистить токен на сервере (при выключении push или выходе).
    func clearTokenOnServer() async {
        guard ConsoleConfigStorage.shared.hasConfig else { return }
        do {
            try await APIService.shared.registerPushToken(nil)
        } catch {
            #if DEBUG
            print("[Push] Failed to clear token: \(error.localizedDescription)")
            #endif
        }
    }
}
