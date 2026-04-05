//
//  CalendarEventService.swift
//  ServiceBooking
//
//  Добавление записи в системный календарь (EventKit).
//

import Foundation
import EventKit

enum CalendarEventError: Error {
    case accessDenied
    case saveFailed(String)
    var message: String {
        switch self {
        case .accessDenied: return "Нет доступа к календарю"
        case .saveFailed(let s): return s
        }
    }
}

enum CalendarEventService {
    static func addBookingToCalendar(serviceName: String, dateTime: Date, durationMinutes: Int) async -> Result<Void, CalendarEventError> {
        let store = EKEventStore()
        do {
            if #available(iOS 17.0, *) {
                try await store.requestWriteOnlyAccessToEvents()
            } else {
                try await store.requestAccess(to: .event)
            }
        } catch {
            return .failure(.accessDenied)
        }
        
        let event = EKEvent(eventStore: store)
        event.title = "Запись: \(serviceName)"
        event.startDate = dateTime
        event.endDate = dateTime.addingTimeInterval(TimeInterval(durationMinutes * 60))
        event.calendar = store.defaultCalendarForNewEvents
        
        do {
            try store.save(event, span: .thisEvent)
            return .success(())
        } catch {
            return .failure(.saveFailed(error.localizedDescription))
        }
    }
}
