// ChildDashboardView.swift
// FamilyGuard
//
// ЗАЧЕМ ЭТОТ ФАЙЛ:
// Дружелюбный экран для ребёнка.
// Ребёнок видит оставшееся время, активные расписания и статус защиты.
// Также содержит экстренную кнопку разблокировки на случай, если опекун потерял свой телефон
// (требует ввода секретного 6-значного Мастер-PIN).

import SwiftUI

public struct ChildDashboardView: View {
    @State private var remainingMinutes: Int = 90
    @State private var nextScheduleText: String = "Сон в 22:00"
    @State private var showEmergencyRecovery: Bool = false
    @State private var showQuickPasscode: Bool = false
    @AppStorage("familyguard.quickPasscodeEnabled") private var isQuickPasscodeEnabled = true
    @AppStorage("familyguard.habitStreakEnabled") private var isHabitStreakEnabled = true
    @ObservedObject private var streakService = HabitStreakService.shared
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // Верхний позитивный баннер
                    VStack(spacing: 12) {
                        Image(systemName: "face.smiling.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 72, height: 72)
                            .foregroundColor(.green)
                            .padding(.top, 16)
                        
                        Text("Отличного дня!")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                        
                        Text("FamilyGuard заботится о балансе твоего времени")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if isHabitStreakEnabled {
                            HStack(spacing: 8) {
                                Image(systemName: "flame.fill")
                                    .foregroundColor(.orange)
                                Text("Серия без нарушений: \(streakService.streak.currentStreakDays) дн. 🔥")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.orange)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(Color.orange.opacity(0.12))
                            .cornerRadius(12)
                        }
                    }
                    
                    // Переход к квестам
                    NavigationLink(destination: ChildQuestsView()) {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(Color.yellow.opacity(0.15))
                                    .frame(width: 44, height: 44)
                                Image(systemName: "star.circle.fill")
                                    .foregroundColor(.yellow)
                                    .font(.title2)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Заработай время!")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                Text("Выполняй задания от опекуна")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(14)
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .cornerRadius(16)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Карточка доступного времени
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "hourglass")
                                .foregroundColor(.blue)
                            Text("Доступное время для игр")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        
                        HStack(alignment: .lastTextBaseline) {
                            Text("1 ч 30 мин")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            StatusBadgeView(status: .secure, label: "В норме")
                        }
                        
                        ProgressView(value: 0.6)
                            .tint(.blue)
                    }
                    .padding(20)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
                    
                    // Карточка ближайшего расписания
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.indigo.opacity(0.12))
                                .frame(width: 50, height: 50)
                            Image(systemName: "moon.stars.fill")
                                .foregroundColor(.indigo)
                                .font(.title3)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Следующее расписание")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text(nextScheduleText)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(16)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .cornerRadius(16)
                    
                    // Информационный блок безопасности
                    HStack(spacing: 12) {
                        Image(systemName: "shield.checkmark.fill")
                            .foregroundColor(.green)
                        
                        Text("Устройство находится под безопасной защитой опекуна.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                    .padding(14)
                    .background(Color.green.opacity(0.08))
                    .cornerRadius(12)
                    
                    // Кнопка экстренного восстановления (на случай утери телефона родителя)
                    Button(action: {
                        showEmergencyRecovery = true
                    }) {
                        HStack {
                            Image(systemName: "key.fill")
                                .font(.caption)
                            Text("Экстренное восстановление (для опекуна)")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                        .padding(.top, 10)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
            }
            .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Моё время")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if isQuickPasscodeEnabled {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showQuickPasscode = true }) {
                            Image(systemName: "key.horizontal")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .sheet(isPresented: $showQuickPasscode) {
                QuickPasscodeModalView()
            }
            .sheet(isPresented: $showEmergencyRecovery) {
                EmergencyRecoveryView()
            }
        }
    }
}
