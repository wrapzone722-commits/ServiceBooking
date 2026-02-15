//
//  ServiceExecutionLiveActivity.swift
//  ServiceBookingWidget
//
//  Live Activity для Dynamic Island - процесс выполнения услуги
//

import ActivityKit
import WidgetKit
import SwiftUI

struct ServiceExecutionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ServiceExecutionAttributes.self) { context in
            // Lock screen / Banner UI
            ServiceExecutionLockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI (при тапе на Dynamic Island)
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        Image(systemName: "car.fill")
                            .font(.title3)
                            .foregroundStyle(Color.cyan)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(context.attributes.serviceName)
                                .font(.caption)
                                .fontWeight(.semibold)
                            Text(context.state.statusText)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        if context.state.statusText == "Ваш авто готов" {
                            Text("Готов")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.green)
                        } else {
                            Text("\(context.state.remainingMinutes) мин")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.cyan)
                            Text("осталось")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 6) {
                        if context.state.statusText == "Ваш авто готов" {
                            Text("Ваш авто готов")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.green)
                            Text("Ожидайте подтверждения администратора в консоли («Завершена»)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        } else {
                            Text(washStageName(context: context))
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.cyan)
                            
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.secondary.opacity(0.3))
                                        .frame(height: 8)
                                    
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.cyan, Color.blue],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: geometry.size.width * context.state.progress, height: 8)
                                    
                                    Image(systemName: "car.fill")
                                        .font(.caption2)
                                        .foregroundStyle(.white)
                                        .offset(x: max(4, min(geometry.size.width * context.state.progress - 8, geometry.size.width - 16)))
                                }
                            }
                            .frame(height: 8)
                            
                            HStack {
                                Text("\(Int(context.state.progress * 100))%")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                Spacer()
                                Text("Осталось \(context.state.remainingMinutes) мин")
                                    .font(.caption2)
                            }
                            .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 12)
                }
            } compactLeading: {
                // Compact leading (левая часть pill)
                Image(systemName: "car.fill")
                    .font(.caption)
                    .foregroundStyle(Color.cyan)
            } compactTrailing: {
                Text(context.state.statusText == "Ваш авто готов" ? "Готов" : "\(context.state.remainingMinutes)м")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(context.state.statusText == "Ваш авто готов" ? Color.green : Color.cyan)
            } minimal: {
                // Minimal (когда несколько активностей)
                Image(systemName: "car.fill")
                    .font(.caption2)
                    .foregroundStyle(Color.cyan)
            }
        }
    }
}

// MARK: - Этап мойки (каждые 2 минуты)

private func washStageName(context: ActivityViewContext<ServiceExecutionAttributes>) -> String {
    let total = context.attributes.totalDuration
    let remaining = context.state.remainingMinutes
    let elapsed = max(0, total - remaining)
    let stage = min(4, elapsed / 2)
    switch stage {
    case 0: return "Ополаскивание"
    case 1: return "Пена"
    case 2: return "Мойка"
    case 3: return "Споласкивание"
    default: return "Сушка"
    }
}

// MARK: - Lock Screen View

struct ServiceExecutionLockScreenView: View {
    let context: ActivityViewContext<ServiceExecutionAttributes>
    
    private var isReady: Bool { context.state.statusText == "Ваш авто готов" }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(context.attributes.serviceName)
                        .font(.headline)
                    Text(context.state.statusText)
                        .font(.caption)
                        .foregroundStyle(isReady ? Color.green : Color.cyan)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    if isReady {
                        Text("Готов")
                            .font(.headline)
                            .foregroundStyle(Color.green)
                    } else {
                        Text("\(context.state.remainingMinutes) мин")
                            .font(.headline)
                            .foregroundStyle(Color.cyan)
                        Text("осталось")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            if isReady {
                Text("Ожидайте подтверждения администратора в консоли («Завершена»)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.secondary.opacity(0.3))
                            .frame(height: 12)
                        
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [Color.cyan, Color.blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * context.state.progress, height: 12)
                        
                        Image(systemName: "car.fill")
                            .font(.caption)
                            .foregroundStyle(.white)
                            .offset(x: max(6, min(geometry.size.width * context.state.progress - 8, geometry.size.width - 16)))
                    }
                }
                .frame(height: 12)
                
                HStack {
                    Text("\(Int(context.state.progress * 100))% завершено")
                        .font(.caption)
                    Spacer()
                    Text("Осталось \(context.state.remainingMinutes) мин")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }
        }
        .padding(16)
    }
}
