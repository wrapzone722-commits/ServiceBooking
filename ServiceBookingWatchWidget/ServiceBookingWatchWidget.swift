//
//  ServiceBookingWatchWidget.swift
//  ServiceBookingWatchWidget
//
//  Виджет для Apple Watch: статус услуги и оставшееся время на циферблате.
//

import WidgetKit
import SwiftUI

struct WatchWidgetEntry: TimelineEntry {
    let date: Date
    let serviceName: String
    let remainingMinutes: Int
    let isActive: Bool
}

struct WatchWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> WatchWidgetEntry {
        WatchWidgetEntry(date: Date(), serviceName: "Химчистка", remainingMinutes: 45, isActive: true)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (WatchWidgetEntry) -> Void) {
        let entry = WatchWidgetEntry(date: Date(), serviceName: "Химчистка", remainingMinutes: 45, isActive: true)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<WatchWidgetEntry>) -> Void) {
        let entry = WatchWidgetEntry(date: Date(), serviceName: "Химчистка салона", remainingMinutes: 45, isActive: true)
        let next = Calendar.current.date(byAdding: .minute, value: 1, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(next))
        completion(timeline)
    }
}

struct ServiceBookingWatchWidgetEntryView: View {
    var entry: WatchWidgetEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        if !entry.isActive {
            Text("Нет активной услуги")
                .font(.caption2)
                .multilineTextAlignment(.center)
        } else {
            switch family {
            case .accessoryCircular:
                VStack(spacing: 2) {
                    Image(systemName: "car.fill")
                        .font(.caption2)
                    Text("\(entry.remainingMinutes)")
                        .font(.title2.monospacedDigit())
                    Text("мин")
                        .font(.caption2)
                }
            case .accessoryRectangular:
                VStack(alignment: .leading, spacing: 4) {
                    Label(entry.serviceName, systemImage: "car.fill")
                        .font(.caption)
                    Text("Осталось \(entry.remainingMinutes) мин")
                        .font(.title3.monospacedDigit())
                }
            case .accessoryInline:
                Text("\(entry.serviceName) — \(entry.remainingMinutes) мин")
                    .font(.caption)
            default:
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "car.fill")
                            .foregroundStyle(.cyan)
                        Text(entry.serviceName)
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    Text("Осталось \(entry.remainingMinutes) мин")
                        .font(.title2.monospacedDigit())
                }
                .padding(.horizontal, 4)
            }
        }
    }
}

struct ServiceBookingWatchWidget: Widget {
    let kind: String = "ServiceBookingWatchWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WatchWidgetProvider()) { entry in
            ServiceBookingWatchWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Запись на услугу")
        .description("Статус текущей услуги и оставшееся время.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

#Preview(as: .accessoryRectangular) {
    ServiceBookingWatchWidget()
} timeline: {
    WatchWidgetEntry(date: Date(), serviceName: "Химчистка салона", remainingMinutes: 45, isActive: true)
}
