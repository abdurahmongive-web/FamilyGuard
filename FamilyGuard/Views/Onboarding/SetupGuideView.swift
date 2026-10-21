// SetupGuideView.swift
// FamilyGuard
//
// ЗАЧЕМ ЭТОТ ФАЙЛ:
// Пошаговая иллюстрированная инструкция по правильной настройке FamilyGuard.
// Объясняет родителю 4 простых шага для безупречной работы контроля.

import SwiftUI

public struct SetupGuideView: View {
    public let onContinue: () -> Void
    
    public init(onContinue: @escaping () -> Void) {
        self.onContinue = onContinue
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            
            VStack(spacing: 8) {
                Text("Как настроить FamilyGuard")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("4 простых шага для безопасного контроля без проводов и паролей")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 24)
            .padding(.horizontal, 20)
            
            ScrollView {
                VStack(spacing: 16) {
                    GuideStepRow(
                        step: "1",
                        icon: "person.2.fill",
                        color: .blue,
                        title: "Семейный доступ Apple",
                        description: "Убедитесь, что iPhone ребёнка добавлен в вашу семейную группу в «Настройках» -> «Семья»."
                    )
                    
                    GuideStepRow(
                        step: "2",
                        icon: "iphone.badge.play",
                        color: .indigo,
                        title: "Установка на оба телефона",
                        description: "Установите FamilyGuard на свой телефон (выберите роль Опекуна) и на телефон ребёнка (роль Ребёнка)."
                    )
                    
                    GuideStepRow(
                        step: "3",
                        icon: "key.fill",
                        color: .orange,
                        title: "Экстренный Мастер-PIN",
                        description: "Задайте 6-значный код восстановления на случай потери вашего телефона."
                    )
                    
                    GuideStepRow(
                        step: "4",
                        icon: "checkmark.shield.fill",
                        color: .green,
                        title: "Готово к защите",
                        description: "Управляйте дневными лимитами, расписаниями сна и блокируйте игры в один клик."
                    )
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
            }
            
            Button(action: onContinue) {
                Text("Понятно, продолжить")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.blue)
                    .cornerRadius(14)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
    }
}

private struct GuideStepRow: View {
    let step: String
    let icon: String
    let color: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 32, height: 32)
                Text(step)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(color)
                    Text(title)
                        .font(.headline)
                }
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}
