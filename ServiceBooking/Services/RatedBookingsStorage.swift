//
//  RatedBookingsStorage.swift
//  ServiceBooking
//
//  Локальное хранение ID записей, которые пользователь уже оценил (п.5 API не меняем).
//

import Foundation

enum RatedBookingsStorage {
    private static let key = "rated_booking_ids"
    
    static func markRated(bookingId: String) {
        var set = Set(load())
        set.insert(bookingId)
        UserDefaults.standard.set(Array(set), forKey: key)
    }
    
    static func isRated(bookingId: String) -> Bool {
        load().contains(bookingId)
    }
    
    private static func load() -> [String] {
        UserDefaults.standard.stringArray(forKey: key) ?? []
    }
}
