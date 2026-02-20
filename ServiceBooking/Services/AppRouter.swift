//
//  AppRouter.swift
//  ServiceBooking
//
//  Навигация на уровне приложения (выход к QR-скану)
//

import Foundation
import SwiftUI

/// Роутер приложения — переход к экрану сканирования QR
final class AppRouter: ObservableObject {
    var onReturnToQRScan: (() -> Void)?
    
    /// Вернуться к экрану сканирования QR (сброс подключения)
    func returnToQRScan() {
        ConsoleConfigStorage.shared.reset()
        APIService.shared.clearAuthToken()
        DispatchQueue.main.async { [weak self] in
            self?.onReturnToQRScan?()
        }
    }
}
