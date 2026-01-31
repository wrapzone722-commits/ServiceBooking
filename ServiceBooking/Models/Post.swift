//
//  Post.swift
//  ServiceBooking
//
//  Модель поста (мойка, бокс) — по спецификации веб-консоли
//

import Foundation

/// Пост / бокс автомойки
struct Post: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let isEnabled: Bool
    let useCustomHours: Bool
    let startTime: String
    let endTime: String
    let intervalMinutes: Int
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name
        case isEnabled = "is_enabled"
        case useCustomHours = "use_custom_hours"
        case startTime = "start_time"
        case endTime = "end_time"
        case intervalMinutes = "interval_minutes"
    }
}
