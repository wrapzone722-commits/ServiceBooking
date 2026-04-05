//
//  AppDelegate.swift
//  ServiceBooking
//
//  Регистрация в APNs и передача device token в PushNotificationService.
//

import UIKit
import UserNotifications

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        // При запуске, если пользователь уже разрешил уведомления и включил push в настройках — регистрируем
        if PushNotificationService.shared.isPushEnabledInSettings {
            PushNotificationService.shared.requestPermissionAndRegisterIfNeeded()
        }
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        PushNotificationService.shared.didRegisterForRemoteNotifications(deviceToken: deviceToken)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        PushNotificationService.shared.didFailToRegisterForRemoteNotifications(error: error)
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    /// Показывать уведомление даже когда приложение на переднем плане
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .badge, .list]
    }
    
    /// Обработка нажатия на уведомление — открыть нужный экран
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        let userInfo = response.notification.request.content.userInfo
        guard let bookingId = userInfo["bookingId"] as? String, !bookingId.isEmpty else { return }
        await MainActor.run {
            NotificationCenter.default.post(
                name: .openBookingFromPush,
                object: nil,
                userInfo: ["bookingId": bookingId]
            )
        }
    }
}

extension Notification.Name {
    static let openBookingFromPush = Notification.Name("openBookingFromPush")
}
