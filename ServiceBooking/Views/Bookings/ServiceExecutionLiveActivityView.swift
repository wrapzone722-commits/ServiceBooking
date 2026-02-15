//
//  ServiceExecutionLiveActivityView.swift
//  ServiceBooking
//
//  Экран для запуска и управления Live Activity
//

import SwiftUI
import ActivityKit

struct ServiceExecutionLiveActivityView: View {
    let booking: Booking
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var activityManager: ServiceExecutionActivityManager
    @State private var isLoading = true
    /// Обновление раз в секунду, чтобы таймер шёл даже после возврата из фона
    @State private var timerTick: Int = 0
    
    var body: some View {
        NavigationStack {
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
                
                ScrollView {
                VStack(spacing: 20) {
                    // Карточка услуги — компактно
                    VStack(alignment: .leading, spacing: 10) {
                        Text(booking.serviceName)
                            .font(.headline)
                            .foregroundStyle(.white)
                        HStack(spacing: 16) {
                            Label(booking.formattedDate, systemImage: "calendar")
                            Label(booking.formattedTime, systemImage: "clock")
                            Text("\(booking.duration) мин")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding(.horizontal, 20)
                    
                    // Статус и текст
                    if isLoading {
                        VStack(spacing: 10) {
                            ProgressView()
                                .tint(.cyan)
                                .scaleEffect(1.2)
                            Text("Запуск…")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                    } else if activityManager.isActivityActive {
                        if activityManager.displayProgress >= 1.0 {
                            // Время истекло — показываем «Ваш авто готов» и напоминание про подтверждение в консоли
                            CarReadyView(
                                serviceName: booking.serviceName,
                                onDismiss: { dismiss() },
                                onStop: {
                                    Task {
                                        await activityManager.stopActivity()
                                        dismiss()
                                    }
                                }
                            )
                            .padding(.horizontal, 20)
                        } else {
                            VStack(spacing: 16) {
                                TimerDisplayView(elapsedSeconds: activityManager.displayElapsedSeconds)
                                
                                CarWashAnimationView(
                                    progress: activityManager.displayProgress,
                                    elapsedMinutes: activityManager.displayElapsedSeconds / 60,
                                    totalMinutes: booking.duration
                                )
                                    .frame(height: 120)
                                    .padding(.vertical, 8)
                                
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 44))
                                    .foregroundStyle(Color.green)
                                
                                Text("Выбранная вами услуга выполняется. Вы можете следить за статусом выполнения в уведомлении вашего устройства. Если вам мешает наш виджет — вы можете его выключить. Мы стараемся сделать наш сервис более удобным для вас.")
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.8))
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(4)
                                    .padding(.horizontal, 8)
                                
                                VStack(spacing: 10) {
                                    Button {
                                        dismiss()
                                    } label: {
                                        HStack(spacing: 8) {
                                            Image(systemName: "arrow.down.circle.fill")
                                                .font(.system(size: 18))
                                            Text("Свернуть приложение")
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                        }
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(
                                            LinearGradient(
                                                colors: [Color.cyan, Color.blue],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    }
                                    
                                    Button {
                                        Task {
                                            await activityManager.stopActivity()
                                            dismiss()
                                        }
                                    } label: {
                                        Text("Остановить и закрыть")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundStyle(.white.opacity(0.6))
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 44))
                                .foregroundStyle(Color.orange)
                            Text("Live Activity недоступна")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                            Button {
                                dismiss()
                            } label: {
                                Text("Закрыть")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.white.opacity(0.2))
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 32)
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Назад") {
                    dismiss()
                }
                .foregroundStyle(.white)
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        }
        .task {
            isLoading = true
            // ВАЖНО: передаём inProgressStartedAt — время когда админ перевёл в «В процессе».
            // Без этого таймер сбрасывался бы при каждом открытии экрана.
            let startTime = booking.inProgressStartedAt ?? booking.dateTime
            await activityManager.startActivity(for: booking, startTime: startTime)
            try? await Task.sleep(nanoseconds: 500_000_000)
            isLoading = false
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            if activityManager.isActivityActive { timerTick += 1 }
        }
        .onDisappear { }
    }
}

// MARK: - Экран «Ваш авто готов» (время истекло, ждём подтверждения администратора)

private struct CarReadyView: View {
    let serviceName: String
    let onDismiss: () -> Void
    let onStop: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "car.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color.green)
            
            Text("Ваш авто готов")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            
            Text("Администратор должен подтвердить действие в консоли, выбрав «Завершена». После подтверждения запись будет отмечена как выполненная.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 8)
            
            VStack(spacing: 10) {
                Button(action: onDismiss) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                        Text("Закрыть")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [Color.cyan, Color.blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                
                Button(action: onStop) {
                    Text("Остановить виджет и закрыть")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
        }
        .padding(.vertical, 16)
    }
}

// MARK: - Таймер (прошло времени)

private struct TimerDisplayView: View {
    let elapsedSeconds: Int
    
    private var minutes: Int { elapsedSeconds / 60 }
    private var seconds: Int { elapsedSeconds % 60 }
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "clock.fill")
                .font(.subheadline)
                .foregroundStyle(Color.cyan)
            Text("Прошло: \(minutes) мин \(seconds) сек")
                .font(.subheadline.monospacedDigit())
                .fontWeight(.medium)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

// MARK: - Анимация мойки машины (этапы каждые 2 мин)

private struct CarWashAnimationView: View {
    let progress: Double
    let elapsedMinutes: Int
    let totalMinutes: Int
    
    /// Этап мойки: каждые 2 минуты новый (0–2 мин, 2–4 мин, …)
    private var washStage: Int { min(4, elapsedMinutes / 2) }
    
    private var stageName: String {
        switch washStage {
        case 0: return "Ополаскивание"
        case 1: return "Пена"
        case 2: return "Мойка"
        case 3: return "Споласкивание"
        default: return "Сушка"
        }
    }
    
    var body: some View {
        VStack(spacing: 10) {
            Text(stageName)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color.cyan)
            
            ZStack(alignment: .leading) {
                // Дорожка прогресса
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.white.opacity(0.15))
                    .frame(height: 10)
                
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            colors: [Color.cyan, Color.blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 200 * progress, height: 10)
                    .animation(.easeInOut(duration: 0.5), value: progress)
                
                // Машинка едет по прогрессу
                Image(systemName: "car.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    .offset(x: max(4, min(200 * progress - 16, 200 - 32)))
                    .animation(.easeInOut(duration: 0.5), value: progress)
            }
            .frame(width: 200, height: 10)
            
            // Капли/пена — анимация по этапу
            HStack(spacing: 6) {
                ForEach(0..<5, id: \.self) { i in
                    Circle()
                        .fill(washStage > i ? Color.cyan.opacity(0.8) : Color.white.opacity(0.2))
                        .frame(width: 8, height: 8)
                        .scaleEffect(washStage > i ? 1.2 : 0.8)
                        .animation(.easeInOut(duration: 0.4).delay(Double(i) * 0.05), value: washStage)
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

#Preview {
    ServiceExecutionLiveActivityView(booking: Booking.preview[0])
        .environmentObject(ServiceExecutionActivityManager())
}
