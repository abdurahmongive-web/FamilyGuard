// WelcomeView.swift
// FamilyGuard
//
// ЗАЧЕМ ЭТОТ ФАЙЛ:
// Экран первого знакомства с приложением (Welcome Onboarding).
// Создаёт первое впечатление и объясняет ценность приложения.

import SwiftUI

public struct WelcomeView: View {
    var onContinue: (() -> Void)? = nil
    
    init(onContinue: (() -> Void)? = nil) {
        self.onContinue = onContinue
    }
    public let onContinue: () -> Void
    
    public init(onContinue: @escaping () -> Void) {
        self.onContinue = onContinue
    }
    
    public var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Логотип приложения
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.12))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "person.badge.shield.checkmark.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 64)
                    .foregroundColor(.blue)
            }
            
            // Заголовок и описание
            VStack(spacing: 12) {
                Text("FamilyGuard")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                
                Text("Умный родительский контроль для здоровых цифровых привычек вашей семьи")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            // Список ключевых возможностей
            VStack(alignment: .leading, spacing: 20) {
                FeatureRow(
                    icon: "hand.raised.fill",
                    color: .orange,
                    title: "Мгновенная блокировка",
                    subtitle: "Блокируйте игры и соцсети в один клик по кнопке Block Now"
                )
                
                FeatureRow(
                    icon: "clock.badge.checkmark.fill",
                    color: .blue,
                    title: "Дневные лимиты",
                    subtitle: "Устанавливайте разумное время для развлечений"
                )
                
                FeatureRow(
                    icon: "moon.stars.fill",
                    color: .indigo,
                    title: "Расписание сна и школы",
                    subtitle: "Автоматическая блокировка на ночь и во время уроков"
                )
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            // Кнопка продолжить
            Button(action: onContinue) {
                Text("Начать")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.blue)
                    .cornerRadius(16)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
    }
}

private struct FeatureRow: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 36)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
