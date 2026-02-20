//
//  BookingsViewModel.swift
//  ServiceBooking
//
//  ViewModel для записей
//  Данные загружаются с сервера, НЕ хранятся локально
//

import Foundation
import SwiftUI

@MainActor
class BookingsViewModel: ObservableObject {
    
    // Данные в памяти
    @Published private(set) var bookings: [Booking] = []
    @Published private(set) var availableSlots: [TimeSlot] = []
    @Published private(set) var posts: [Post] = []
    
    // Выбор для новой записи
    @Published var selectedDate: Date = Date()
    @Published var selectedSlot: TimeSlot?
    @Published var selectedPostId: String = "post_1"
    
    // Состояние
    @Published private(set) var isLoading = false
    @Published private(set) var isSlotsLoading = false
    @Published var errorMessage: String?
    @Published var showSuccessAlert = false
    
    // MARK: - Computed
    
    var upcomingBookings: [Booking] {
        bookings.filter { !$0.isPast && $0.status != .cancelled }
            .sorted { $0.dateTime < $1.dateTime }
    }
    
    var pastBookings: [Booking] {
        bookings.filter { $0.isPast || $0.status == .completed }
            .sorted { $0.dateTime > $1.dateTime }
    }
    
    var cancelledBookings: [Booking] {
        bookings.filter { $0.status == .cancelled }
            .sorted { $0.dateTime > $1.dateTime }
    }
    
    /// Доступные слоты для выбора: только свободные и только будущее время (прошедшие не показываем)
    var availableSlotsForSelection: [TimeSlot] {
        let now = Date()
        return availableSlots.filter { $0.isAvailable && $0.time >= now }
    }
    
    // MARK: - API Methods
    
    /// Загрузить записи с сервера
    func loadBookings(silentRefresh: Bool = false) async {
        isLoading = true
        if !silentRefresh {
            errorMessage = nil
        }
        
        do {
            bookings = try await APIService.shared.fetchBookings()
            if silentRefresh {
                errorMessage = nil // Очищаем ошибку только при успехе
            }
        } catch {
            // При silent refresh не показываем ошибку сразу, даём больше времени
            if !silentRefresh {
                errorMessage = error.localizedDescription
                bookings = []
            } else {
                // При pull-to-refresh показываем ошибку только если данных нет совсем
                if bookings.isEmpty {
                    // Задержка перед показом ошибки при refresh
                    try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 секунды
                    if bookings.isEmpty {
                        errorMessage = error.localizedDescription
                    }
                }
            }
        }
        
        isLoading = false
    }
    
    /// Сбросить ошибку (выход с экрана ошибки)
    func clearError() {
        errorMessage = nil
    }
    
    /// Загрузить посты (боксы)
    func loadPosts() async {
        do {
            posts = try await APIService.shared.fetchPosts()
            if selectedPostId.isEmpty || !posts.contains(where: { $0.id == selectedPostId }) {
                selectedPostId = posts.first { $0.isEnabled }?.id ?? "post_1"
            }
        } catch {
            errorMessage = error.localizedDescription
            posts = []
            if selectedPostId.isEmpty { selectedPostId = "post_1" }
        }
    }
    
    /// Загрузить слоты с сервера
    func loadAvailableSlots(serviceId: String, date: Date, postId: String? = nil) async {
        isSlotsLoading = true
        selectedSlot = nil
        
        let effectivePostId = postId ?? selectedPostId
        
        do {
            availableSlots = try await APIService.shared.fetchAvailableSlots(
                serviceId: serviceId,
                date: date,
                postId: effectivePostId
            )
        } catch {
            errorMessage = error.localizedDescription
            availableSlots = []
        }
        
        isSlotsLoading = false
    }
    
    /// Создать запись (отправить на сервер)
    func createBooking(serviceId: String, notes: String?) async -> Bool {
        guard let slot = selectedSlot else {
            errorMessage = "Выберите время"
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let request = CreateBookingRequest(
                serviceId: serviceId,
                dateTime: slot.time,
                postId: selectedPostId,
                notes: notes
            )
            
            let newBooking = try await APIService.shared.createBooking(request: request)
            
            // Добавляем в локальный список (до следующей загрузки)
            bookings.insert(newBooking, at: 0)
            showSuccessAlert = true
            resetSelection()
            
            isLoading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
    
    /// Отменить запись
    func cancelBooking(_ booking: Booking) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await APIService.shared.cancelBooking(id: booking.id)
            
            // Перезагружаем список с сервера для актуальных данных
            await loadBookings()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Selection
    
    func selectDate(_ date: Date) {
        selectedDate = date
        selectedSlot = nil
    }
    
    func selectSlot(_ slot: TimeSlot) {
        withAnimation { selectedSlot = slot }
    }
    
    func resetSelection() {
        selectedDate = Date()
        selectedSlot = nil
        availableSlots = []
        selectedPostId = posts.first { $0.isEnabled }?.id ?? "post_1"
    }
    
    /// Очистить все данные
    func clear() {
        bookings = []
        availableSlots = []
        resetSelection()
    }
}
