//
//  ServicesViewModel.swift
//  ServiceBooking
//
//  ViewModel для услуг
//  Данные загружаются с сервера, НЕ хранятся локально
//

import Foundation
import SwiftUI

@MainActor
class ServicesViewModel: ObservableObject {
    
    // Данные в памяти (НЕ сохраняются при закрытии)
    @Published private(set) var services: [Service] = []
    @Published private(set) var categories: [String] = []
    @Published var selectedCategory: String?
    @Published var searchText: String = ""
    
    // Состояние загрузки
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    
    /// Отфильтрованные услуги
    var filteredServices: [Service] {
        var result = services
        
        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }
        
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return result
    }
    
    /// Загрузить услуги с сервера
    func loadServices(silentRefresh: Bool = false) async {
        isLoading = true
        if !silentRefresh {
            errorMessage = nil
        }
        
        do {
            services = try await APIService.shared.fetchServices()
            categories = Array(Set(services.map { $0.category })).sorted()
            if silentRefresh {
                errorMessage = nil // Очищаем ошибку только при успехе
            }
        } catch {
            // При silent refresh не показываем ошибку сразу, даём больше времени
            if !silentRefresh {
                errorMessage = error.localizedDescription
                services = []
            } else {
                // При pull-to-refresh показываем ошибку только если данных нет совсем
                if services.isEmpty {
                    // Задержка перед показом ошибки при refresh
                    try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 секунды
                    if services.isEmpty {
                        errorMessage = error.localizedDescription
                    }
                }
            }
        }
        
        isLoading = false
    }
    
    /// Обновить данные (pull-to-refresh)
    func refresh() async {
        await loadServices(silentRefresh: true)
    }
    
    /// Выбрать категорию
    func selectCategory(_ category: String?) {
        withAnimation {
            selectedCategory = selectedCategory == category ? nil : category
        }
    }
    
    /// Очистить данные (при выходе)
    func clear() {
        services = []
        categories = []
        selectedCategory = nil
        searchText = ""
    }
    
    /// Сбросить ошибку (выход с экрана ошибки)
    func clearError() {
        errorMessage = nil
    }
}
