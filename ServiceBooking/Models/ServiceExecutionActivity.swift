//
//  ServiceExecutionActivity.swift
//  ServiceBooking
//
//  Live Activity для отображения процесса выполнения услуги в Dynamic Island
//

import Foundation
import ActivityKit

/// Атрибуты Live Activity (неизменяемые данные)
struct ServiceExecutionAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Динамические данные (обновляемые)
        var progress: Double // 0.0 - 1.0
        var remainingMinutes: Int
        var statusText: String
    }
    
    // Статические данные (не меняются во время Activity)
    let bookingId: String
    let serviceName: String
    let startTime: Date
    let totalDuration: Int // в минутах
}

/// Менеджер для управления Live Activity
@MainActor
class ServiceExecutionActivityManager: ObservableObject {
    @Published private(set) var currentActivity: Activity<ServiceExecutionAttributes>?
    @Published private(set) var isActivityActive = false
    @Published private(set) var elapsedSeconds: Int = 0
    @Published private(set) var progress: Double = 0
    @Published private(set) var remainingMinutes: Int = 0
    
    private var updateTimer: Timer?
    
    /// Прошло секунд от времени старта — не сбрасывается при сворачивании приложения
    var displayElapsedSeconds: Int {
        guard let activity = currentActivity else { return elapsedSeconds }
        let totalSec = activity.attributes.totalDuration * 60
        let elapsed = Int(Date().timeIntervalSince(activity.attributes.startTime))
        return min(max(0, elapsed), totalSec)
    }
    
    /// Прогресс 0...1, считается от времени старта
    var displayProgress: Double {
        guard let activity = currentActivity else { return progress }
        let totalSec = Double(activity.attributes.totalDuration * 60)
        let elapsed = Date().timeIntervalSince(activity.attributes.startTime)
        return min(1.0, max(0, elapsed / totalSec))
    }
    
    /// Осталось минут, считается от времени старта
    var displayRemainingMinutes: Int {
        guard let activity = currentActivity else { return remainingMinutes }
        let totalSec = activity.attributes.totalDuration * 60
        let elapsed = displayElapsedSeconds
        return max(0, (totalSec - elapsed + 59) / 60)
    }
    
    /// Запустить Live Activity для услуги.
    /// - Parameters:
    ///   - booking: запись по услуге
    ///   - startTime: время начала (если nil — «сейчас»; при автозапуске передать booking.dateTime или in_progress_started_at с сервера)
    func startActivity(for booking: Booking, startTime: Date? = nil) async {
        // Проверяем поддержку Live Activities
        let authInfo = ActivityAuthorizationInfo()
        guard authInfo.areActivitiesEnabled else {
            print("❌ Live Activities не разрешены пользователем")
            print("Статус: \(authInfo.areActivitiesEnabled)")
            isActivityActive = false
            return
        }
        
        // Если уже показываем эту же запись — не перезапускаем
        if let current = currentActivity, current.attributes.bookingId == booking.id {
            return
        }
        
        // Останавливаем предыдущую активность если есть
        await stopActivity()
        
        // Приоритет: переданное startTime → inProgressStartedAt с сервера → дата записи.
        // Никогда не используем Date() — иначе таймер сбрасывается при каждом открытии экрана.
        let effectiveStartTime = startTime ?? booking.inProgressStartedAt ?? booking.dateTime
        let attributes = ServiceExecutionAttributes(
            bookingId: booking.id,
            serviceName: booking.serviceName,
            startTime: effectiveStartTime,
            totalDuration: booking.duration
        )
        
        let totalSec = Double(booking.duration * 60)
        let elapsed = Date().timeIntervalSince(effectiveStartTime)
        let progress = min(1.0, max(0, elapsed / totalSec))
        let remainingSec = max(0, totalSec - elapsed)
        let remainingMinutes = Int(ceil(remainingSec / 60))
        let statusText: String = progress >= 1.0 ? "Ваш авто готов" : (progress < 0.3 ? "Начало работы" : (progress < 0.7 ? "В процессе" : "Завершение"))
        
        let initialState = ServiceExecutionAttributes.ContentState(
            progress: progress,
            remainingMinutes: remainingMinutes,
            statusText: statusText
        )
        
        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )
            
            currentActivity = activity
            isActivityActive = true
            
            // Запускаем таймер для обновления прогресса (используем effectiveStartTime для расчёта)
            startProgressTimer(totalDuration: booking.duration, from: effectiveStartTime)
            
            print("✅ Live Activity запущена: \(activity.id)")
        } catch {
            print("❌ Ошибка запуска Live Activity: \(error)")
        }
    }
    
    /// Обновить состояние Live Activity
    func updateActivity(progress: Double, remainingMinutes: Int, statusText: String) async {
        guard let activity = currentActivity else { return }
        
        let updatedState = ServiceExecutionAttributes.ContentState(
            progress: progress,
            remainingMinutes: remainingMinutes,
            statusText: statusText
        )
        
        await activity.update(
            .init(state: updatedState, staleDate: nil)
        )
    }
    
    /// Завершить Live Activity
    func stopActivity() async {
        guard let activity = currentActivity else { return }
        
        // Останавливаем таймер
        updateTimer?.invalidate()
        updateTimer = nil
        
        // Финальное обновление
        let finalState = ServiceExecutionAttributes.ContentState(
            progress: 1.0,
            remainingMinutes: 0,
            statusText: "Завершено"
        )
        
        await activity.update(
            .init(state: finalState, staleDate: nil)
        )
        
        // Завершаем Activity через 3 секунды
        try? await Task.sleep(nanoseconds: 3_000_000_000)
        await activity.end(nil, dismissalPolicy: .immediate)
        
        currentActivity = nil
        isActivityActive = false
        elapsedSeconds = 0
        progress = 0
        remainingMinutes = 0
        
        print("✅ Live Activity завершена")
    }
    
    /// Запустить таймер для автоматического обновления прогресса.
    /// startTime — время когда админ перевёл в «В процессе»; НЕ должен быть Date().
    private func startProgressTimer(totalDuration: Int, from startTime: Date) {
        let totalSeconds = Double(totalDuration * 60)
        
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            let elapsed = Date().timeIntervalSince(startTime)
            let progress = min(1.0, elapsed / totalSeconds)
            let remainingSeconds = max(0, totalSeconds - elapsed)
            let remainingMinutes = Int(ceil(remainingSeconds / 60))
            
            let statusText: String
            if progress >= 1.0 {
                statusText = "Ваш авто готов"
            } else if progress < 0.3 {
                statusText = "Начало работы"
            } else if progress < 0.7 {
                statusText = "В процессе"
            } else {
                statusText = "Завершение"
            }
            
            Task { @MainActor in
                self.elapsedSeconds = Int(elapsed)
                self.progress = progress
                self.remainingMinutes = remainingMinutes
                await self.updateActivity(
                    progress: progress,
                    remainingMinutes: remainingMinutes,
                    statusText: statusText
                )
                if progress >= 1.0 {
                    self.updateTimer?.invalidate()
                    self.updateTimer = nil
                }
            }
        }
        updateTimer?.tolerance = 0.3
    }
    
    deinit {
        updateTimer?.invalidate()
    }
}
