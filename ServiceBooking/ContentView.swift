//
//  ContentView.swift
//  ServiceBooking
//
//  Главный экран с Tab навигацией
//  Стиль iOS — поддержка светлой и тёмной темы
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Услуги")
                }
                .tag(0)
            
            BookingsView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Мои записи")
                }
                .tag(1)
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Профиль")
                }
                .tag(2)
        }
        .tint(Color.accentColor)
    }
}

#Preview {
    ContentView()
        .environmentObject(ServicesViewModel())
        .environmentObject(BookingsViewModel())
        .environmentObject(ProfileViewModel())
        .environmentObject(AppRouter())
}
