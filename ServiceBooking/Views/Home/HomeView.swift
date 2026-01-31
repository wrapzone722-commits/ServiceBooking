//
//  HomeView.swift
//  ServiceBooking
//
//  Главная страница — список услуг
//  Стиль iOS 26 — светлая и тёмная темы
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var viewModel: ServicesViewModel
    @EnvironmentObject var appRouter: AppRouter
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @State private var selectedService: Service?
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Системный фон (адаптируется к теме)
                AppTheme.background
                    .ignoresSafeArea()
                
                content
                
                if !networkMonitor.isConnected {
                    VStack {
                        NoConnectionBanner()
                            .padding(.top, 8)
                        Spacer()
                    }
                }
            }
            .navigationTitle("Услуги")
            .navigationBarTitleDisplayMode(.large)
            .refreshable { await viewModel.refresh() }
            .onAppear { Task { await viewModel.loadServices() } }
            .sheet(item: $selectedService) { service in
                ServiceDetailView(service: service)
            }
        }
    }
    
    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.services.isEmpty {
            LoadingView(message: "Загрузка услуг...")
        } else if let error = viewModel.errorMessage, viewModel.services.isEmpty {
            ErrorView(message: error, retryAction: {
                await viewModel.loadServices()
            }, onUseDemoFallback: {
                ConsoleConfigStorage.shared.reset()
                APIConfig.useMockData = true
                Task { await viewModel.loadServices() }
            }, onDismiss: {
                viewModel.clearError()
                appRouter.returnToQRScan()
            })
        } else {
            servicesList
        }
    }
    
    private var servicesList: some View {
        ScrollView {
            VStack(spacing: 20) {
                searchBar
                
                if !viewModel.categories.isEmpty {
                    categoriesSection
                }
                
                servicesSection
            }
            .padding()
        }
        .scrollContentBackground(.hidden)
    }
    
    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.body)
                .foregroundStyle(AppTheme.secondaryLabel)
            
            TextField("Поиск услуг", text: $viewModel.searchText)
                .textFieldStyle(.plain)
            
            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.body)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(AppTheme.secondaryLabel)
                }
            }
        }
        .padding(12)
        .background(AppTheme.tertiaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
    
    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Категории")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(AppTheme.label)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    CategoryChip(title: "Все", isSelected: viewModel.selectedCategory == nil) {
                        viewModel.selectCategory(nil)
                    }
                    
                    ForEach(viewModel.categories, id: \.self) { category in
                        CategoryChip(title: category, isSelected: viewModel.selectedCategory == category) {
                            viewModel.selectCategory(category)
                        }
                    }
                }
            }
        }
    }
    
    private var servicesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Доступные услуги")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.label)
                Spacer()
                Text("\(viewModel.filteredServices.count)")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryLabel)
            }
            
            if viewModel.filteredServices.isEmpty {
                EmptyStateView(
                    icon: "tray",
                    title: "Услуги не найдены",
                    subtitle: "Попробуйте изменить параметры поиска"
                )
                .frame(height: 200)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.filteredServices) { service in
                        ServiceCard(service: service)
                            .onTapGesture { selectedService = service }
                    }
                }
            }
        }
    }
}

// MARK: - Category Chip

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : AppTheme.tertiaryBackground)
                .foregroundStyle(isSelected ? .white : AppTheme.label)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Service Card

struct ServiceCard: View {
    let service: Service
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(service.name)
                        .font(.headline)
                        .foregroundStyle(AppTheme.label)
                    
                    Text(service.category)
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryLabel)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppTheme.tertiaryBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(service.formattedPrice)
                        .font(.headline)
                        .foregroundStyle(Color.accentColor)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text(service.formattedDuration)
                            .font(.caption)
                    }
                    .foregroundStyle(AppTheme.secondaryLabel)
                }
            }
            
            Text(service.description)
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryLabel)
                .lineLimit(2)
            
            HStack {
                Spacer()
                Text("Записаться")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.accentColor)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.accentColor)
            }
        }
        .padding()
        .background(AppTheme.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
    }
}

#Preview {
    HomeView()
        .environmentObject(ServicesViewModel())
        .environmentObject(BookingsViewModel())
        .environmentObject(AppRouter())
}
