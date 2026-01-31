//
//  SplashView.swift
//  ServiceBooking
//
//  Анимированный экран запуска с паттерном из точек
//

import SwiftUI

struct SplashView: View {
    @State private var isAnimating = false
    @State private var showContent = false
    @Binding var isFinished: Bool
    
    // Параметры сетки точек
    private let rows = 11
    private let cols = 11
    private let maxDotSize: CGFloat = 12
    private let minDotSize: CGFloat = 2
    private let spacing: CGFloat = 16
    
    var body: some View {
        ZStack {
            // Фон
            Color.black
                .ignoresSafeArea()
            
            // Сетка точек
            VStack(spacing: spacing) {
                ForEach(0..<rows, id: \.self) { row in
                    HStack(spacing: spacing) {
                        ForEach(0..<cols, id: \.self) { col in
                            DotView(
                                row: row,
                                col: col,
                                totalRows: rows,
                                totalCols: cols,
                                maxSize: maxDotSize,
                                minSize: minDotSize,
                                isAnimating: isAnimating
                            )
                        }
                    }
                }
            }
            .opacity(showContent ? 1 : 0)
            .scaleEffect(showContent ? 1 : 0.5)
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        // Появление точек
        withAnimation(.easeOut(duration: 0.6)) {
            showContent = true
        }
        
        // Пульсация точек
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 0.8).repeatCount(2, autoreverses: true)) {
                isAnimating = true
            }
        }
        
        // Завершение анимации
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeIn(duration: 0.4)) {
                showContent = false
            }
        }
        
        // Переход к основному приложению
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation {
                isFinished = true
            }
        }
    }
}

// MARK: - Dot View

struct DotView: View {
    let row: Int
    let col: Int
    let totalRows: Int
    let totalCols: Int
    let maxSize: CGFloat
    let minSize: CGFloat
    let isAnimating: Bool
    
    var body: some View {
        Circle()
            .fill(Color.white)
            .frame(width: dotSize, height: dotSize)
            .opacity(dotOpacity)
            .scaleEffect(isAnimating ? pulseScale : 1.0)
            .animation(
                .easeInOut(duration: 0.6)
                .delay(animationDelay)
                .repeatForever(autoreverses: true),
                value: isAnimating
            )
    }
    
    // Расчёт размера точки на основе расстояния от центра
    private var dotSize: CGFloat {
        let centerRow = Double(totalRows) / 2.0
        let centerCol = Double(totalCols) / 2.0
        
        let distanceFromCenter = sqrt(
            pow(Double(row) - centerRow, 2) +
            pow(Double(col) - centerCol, 2)
        )
        
        let maxDistance = sqrt(pow(centerRow, 2) + pow(centerCol, 2))
        let normalizedDistance = distanceFromCenter / maxDistance
        
        // Инвертируем: ближе к центру = больше
        let sizeFactor = 1.0 - normalizedDistance
        return minSize + (maxSize - minSize) * sizeFactor
    }
    
    // Прозрачность на основе расстояния от центра
    private var dotOpacity: Double {
        let centerRow = Double(totalRows) / 2.0
        let centerCol = Double(totalCols) / 2.0
        
        let distanceFromCenter = sqrt(
            pow(Double(row) - centerRow, 2) +
            pow(Double(col) - centerCol, 2)
        )
        
        let maxDistance = sqrt(pow(centerRow, 2) + pow(centerCol, 2))
        let normalizedDistance = distanceFromCenter / maxDistance
        
        // Градиент прозрачности
        return max(0.3, 1.0 - normalizedDistance * 0.8)
    }
    
    // Задержка анимации (волна от центра)
    private var animationDelay: Double {
        let centerRow = Double(totalRows) / 2.0
        let centerCol = Double(totalCols) / 2.0
        
        let distanceFromCenter = sqrt(
            pow(Double(row) - centerRow, 2) +
            pow(Double(col) - centerCol, 2)
        )
        
        return distanceFromCenter * 0.05
    }
    
    // Масштаб пульсации
    private var pulseScale: CGFloat {
        let centerRow = Double(totalRows) / 2.0
        let centerCol = Double(totalCols) / 2.0
        
        let distanceFromCenter = sqrt(
            pow(Double(row) - centerRow, 2) +
            pow(Double(col) - centerCol, 2)
        )
        
        let maxDistance = sqrt(pow(centerRow, 2) + pow(centerCol, 2))
        let normalizedDistance = distanceFromCenter / maxDistance
        
        // Центральные точки пульсируют сильнее
        return 1.0 + (1.0 - normalizedDistance) * 0.3
    }
}

// MARK: - Preview

#Preview {
    SplashView(isFinished: .constant(false))
}
