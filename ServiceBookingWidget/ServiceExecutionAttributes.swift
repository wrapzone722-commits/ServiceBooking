//
//  ServiceExecutionAttributes.swift
//  ServiceBookingWidget
//
//  Модель атрибутов для Live Activity (копия для Widget target)
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
