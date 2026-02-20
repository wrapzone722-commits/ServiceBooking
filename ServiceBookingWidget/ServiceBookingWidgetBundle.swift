//
//  ServiceBookingWidgetBundle.swift
//  ServiceBookingWidget
//
//  Widget Bundle для Live Activity
//

import WidgetKit
import SwiftUI
import AppIntents

@main
struct ServiceBookingWidgetBundle: WidgetBundle {
    var body: some Widget {
        ServiceExecutionLiveActivity()
    }
}

@available(iOS 16.0, *)
private struct _AppIntentsDependency: AppIntent {
    static var title: LocalizedStringResource = "ServiceBooking"
    func perform() async throws -> some IntentResult { .result() }
}
