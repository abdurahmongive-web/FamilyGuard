// GrantExtraTimeSheet.swift
// FamilyGuard
//
// ЗАЧЕМ ЭТОТ ФАЙЛ:
// Модальный экран для родителя: выдача дополнительного времени
// (+15 минут, +30 минут, +1 час, +2-3 часа или без лимита на сегодня).

import SwiftUI

public struct GrantExtraTimeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var managedSettingsService: ManagedSettingsService
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                
                // Верхний блок с иконкой
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.12))
                            .frame(width: 68, height: 68)
                        Image(systemName: "hourglass.badge.plus")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 36, height: 36)
                            .foregroundColor(.orange)
                    }
                    .padding(.top, 16)
                    
                    Text("Добавить время")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Выберите, на сколько продлить доступ ребёнку сверх установленного лимита.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                
                // Список вариантов
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(ExtraTimeOption.allCases) { option in
                            Button(action: {
                                if option == .unlimitedToday {
                                    managedSettingsService.removeDailyLimitForToday()
                                } else {
                                    managedSettingsService.grantBonusTime(minutes: option.minutes)
                                }
                                dismiss()
                            }) {
                                HStack(spacing: 16) {
                                    Image(systemName: option.icon)
                                        .font(.title3)
                                        .foregroundColor(option == .unlimitedToday ? .green : .orange)
                                        .frame(width: 32)
                                    
                                    Text(option.title)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(16)
                                .background(Color(uiColor: .secondarySystemGroupedBackground))
                                .cornerRadius(16)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                }
                
                Spacer()
            }
            .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Продление времени")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
            }
        }
    }
}
