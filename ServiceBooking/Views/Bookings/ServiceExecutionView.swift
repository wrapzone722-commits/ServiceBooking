//
//  ServiceExecutionView.swift
//  ServiceBooking
//
//  Окно процесса выполнения услуги с анимацией прогресса
//

import SwiftUI

struct ServiceExecutionView: View {
    let booking: Booking
    @Environment(\.dismiss) private var dismiss
    @StateObject private var progressManager = ServiceProgressManager()
    
    var body: some View {
        ZStack {
            // Фоновый градиент
            LinearGradient(
                colors: [
                    Color.black.opacity(0.95),
                    Color.black.opacity(0.85)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Заголовок
                headerSection
                    .padding(.top, 60)
                    .padding(.horizontal, 24)
                
                Spacer()
                
                // Основная карточка процесса
                processCard
                    .padding(.horizontal, 20)
                
                Spacer()
                
                // Кнопки действий
                actionButtons
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
            }
        }
        .onAppear {
            progressManager.startProgress(duration: booking.duration)
        }
        .onDisappear {
            progressManager.stopProgress()
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Выполнение услуги")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.white.opacity(0.9))
            
            Text(booking.serviceName)
                .font(.headline)
                .foregroundStyle(.white)
        }
    }
    
    private var processCard: some View {
        VStack(spacing: 0) {
            // Верхняя секция с информацией
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(booking.serviceName)
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                        Text(booking.formattedDate)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(booking.formattedPrice)
                            .font(.body)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.accentColor)
                        Text(booking.formattedTime)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                Divider()
                    .background(.white.opacity(0.2))
                    .padding(.horizontal, 20)
                
                // Прогресс-бар с анимированной иконкой
                progressSection
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                
                Divider()
                    .background(.white.opacity(0.2))
                    .padding(.horizontal, 20)
                
                // Информация об исполнителе
                executorSection
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
    }
    
    private var progressSection: some View {
        VStack(spacing: 16) {
            // Прогресс-бар
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Фоновая полоса
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.15))
                        .frame(height: 24)
                    
                    // Заполненная часть с градиентом
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.cyan.opacity(0.8),
                                    Color.blue.opacity(0.8)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(progressManager.progress), height: 24)
                        .shadow(color: Color.cyan.opacity(0.5), radius: 8, x: 0, y: 0)
                    
                    // Анимированная иконка
                    Image(systemName: "car.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                        .offset(
                            x: max(12, min(geometry.size.width * CGFloat(progressManager.progress) - 12, geometry.size.width - 24))
                        )
                        .animation(.linear(duration: 1), value: progressManager.progress)
                }
            }
            .frame(height: 24)
            
            // Статус и оставшееся время
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(progressManager.statusText)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                    Text("\(Int(progressManager.progress * 100))% завершено")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(progressManager.remainingTimeText)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.cyan)
                    Text("осталось")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
        }
    }
    
    private var executorSection: some View {
        HStack(spacing: 16) {
            // Аватар исполнителя
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.cyan.opacity(0.3), Color.blue.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                
                Image(systemName: "person.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.white.opacity(0.8))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Исполнитель")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                Text("Мастер сервиса")
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
            }
            
            Spacer()
            
            // Кнопка звонка
            Button {
                // Действие звонка
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: "phone.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.green)
                }
            }
            .buttonStyle(.plain)
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Кнопка "Связаться с поддержкой"
            Button {
                // Действие связи с поддержкой
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "message.fill")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Связаться с поддержкой")
                        .font(.body)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.15))
                )
            }
            .buttonStyle(.plain)
            
            // Кнопка "Закрыть"
            Button {
                dismiss()
            } label: {
                Text("Закрыть")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Progress Manager

class ServiceProgressManager: ObservableObject {
    @Published var progress: Double = 0.0
    @Published var remainingTime: Int = 0 // в секундах
    
    private var timer: Timer?
    private var totalDuration: Int = 0 // в минутах
    private var elapsedTime: Int = 0 // в секундах
    
    var statusText: String {
        if progress < 0.3 {
            return "Начало работы"
        } else if progress < 0.7 {
            return "В процессе"
        } else if progress < 1.0 {
            return "Завершение"
        } else {
            return "Завершено"
        }
    }
    
    var remainingTimeText: String {
        let minutes = remainingTime / 60
        let seconds = remainingTime % 60
        
        if minutes > 0 {
            return "\(minutes) мин"
        } else {
            return "\(seconds) сек"
        }
    }
    
    func startProgress(duration: Int) {
        totalDuration = duration
        remainingTime = duration * 60 // конвертируем минуты в секунды
        elapsedTime = 0
        progress = 0.0
        
        // Обновляем прогресс каждую секунду
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            self.elapsedTime += 1
            self.remainingTime = max(0, (self.totalDuration * 60) - self.elapsedTime)
            
            // Вычисляем прогресс (0.0 - 1.0)
            let totalSeconds = Double(self.totalDuration * 60)
            self.progress = min(1.0, Double(self.elapsedTime) / totalSeconds)
            
            // Останавливаем таймер при завершении
            if self.progress >= 1.0 {
                self.stopProgress()
            }
        }
    }
    
    func stopProgress() {
        timer?.invalidate()
        timer = nil
    }
    
    deinit {
        stopProgress()
    }
}

#Preview {
    ServiceExecutionView(booking: Booking.preview[0])
}
