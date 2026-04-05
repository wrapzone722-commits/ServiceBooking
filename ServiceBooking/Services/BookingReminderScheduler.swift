//
//  BookingReminderScheduler.swift
//  ServiceBooking
//
//  Локальные напоминания о записи (UNUserNotificationCenter).
//

import Foundation
import UserNotifications

enum BookingReminderScheduler {
    private static let categoryId = "booking_reminder"
    private static func notificationId(bookingId: String) -> String { "booking_\(bookingId)" }
    
    /// Запросить разрешение и запланировать напоминание
    static func schedule(bookingId: String, serviceName: String, dateTime: Date, reminderTiming: ReminderTiming) {
        let content = UNMutableNotificationContent()
        content.title = "Напоминание о записи"
        content.body = "Через \(reminderTiming.displayName.lowercased()): \(serviceName)"
        content.sound = .default
        content.userInfo = ["bookingId": bookingId]
        content.categoryIdentifier = categoryId
        
        let triggerDate = dateTime.addingTimeInterval(-reminderTiming.timeInterval)
        guard triggerDate > Date() else { return }
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: notificationId(bookingId: bookingId), content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
        UNUserNotificationCenter.current().add(request)
    }
    
    /// Отменить напоминание по записи (при отмене записи)
    static func cancel(bookingId: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationId(bookingId: bookingId)])
    }
}
