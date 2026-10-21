// RoleSelectionView.swift
// FamilyGuard
//
// ЗАЧЕМ ЭТОТ ФАЙЛ:
// Экран выбора роли устройства: "Опекун / Родитель" или "Ребёнок".

import SwiftUI

public struct RoleSelectionView: View {
    public let onSelectRole: (UserRole) -> Void
    
    public init(onSelectRole: @escaping (UserRole) -> Void) {
        self.onSelectRole = onSelectRole
    }
    
    public var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Кто использует это устройство?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Выберите роль для настройки интерфейса и прав доступа")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)
            .padding(.horizontal, 20)
            
            Spacer()
            
            VStack(spacing: 20) {
                // Карточка Опекуна
                Button(action: { onSelectRole(.parent) }) {
                    RoleCard(
                        title: "Родитель / Опекун",
                        subtitle: "Управление правилами, блокировками и просмотр активности",
                        icon: "person.badge.shield.checkmark.fill",
                        color: .blue
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                // Карточка Ребёнка
                Button(action: { onSelectRole(.child) }) {
                    RoleCard(
                        title: "Ребёнок",
                        subtitle: "Просмотр доступного времени и активных расписаний",
                        icon: "face.smiling.fill",
                        color: .green
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
    }
}

private struct RoleCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 60, height: 60)
                
                Image(systemName: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding(18)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}
