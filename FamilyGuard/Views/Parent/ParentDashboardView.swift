// ParentDashboardView.swift
// FamilyGuard
//
// ЗАЧЕМ ЭТОТ ФАЙЛ:
// Главная панель управления Опекуна.
// Включает:
// 1. Мгновенную блокировку (Block Now / All Access Blocked)
// 2. Кнопку продления времени (+15м, +30м, +1ч, +2-3ч, Снять лимит)
// 3. Тумблер пропуска ночного режима на сегодня
// 4. Управление приложениями, лимитами и расписаниями

import SwiftUI
import FamilyControls

public struct ParentDashboardView: View {
    @EnvironmentObject private var familyControlsService: FamilyControlsService
    @EnvironmentObject private var managedSettingsService: ManagedSettingsService
    
    @State private var showAppPicker = false
    @State private var showExtraTimeSheet = false
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // 1. Верхний интерактивный баннер блокировки
                    BlockControlCard(
                        isBlocked: managedSettingsService.isBlockNowActive,
                        isLimitSuspended: managedSettingsService.isDailyLimitSuspendedToday,
                        onToggleBlock: {
                            if managedSettingsService.isBlockNowActive {
                                managedSettingsService.unblock()
                            } else {
                                managedSettingsService.blockNow(selection: familyControlsService.activitySelection)
                            }
                        },
                        onGrantExtraTime: {
                            showExtraTimeSheet = true
                        }
                    )
                    
                    // 2. Блок разрешения играть ночью на сегодня
                    NightModeOverrideCard(
                        isSuspended: managedSettingsService.isBedtimeSuspendedTonight,
                        onToggle: {
                            managedSettingsService.toggleBedtimeForTonight()
                        }
                    )
                    
                    // 3. Секция контролируемых приложений
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Выбранные приложения")
                                .font(.headline)
                            Text("\(familyControlsService.activitySelection.applicationTokens.count) приложений, \(familyControlsService.activitySelection.categoryTokens.count) категорий")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("Настроить") {
                            showAppPicker = true
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                    }
                    .padding(16)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .cornerRadius(16)
                    
                    // 4. Меню настроек (Лимиты, Расписания, Защита от удаления)
                    VStack(spacing: 12) {
                        NavigationLink(destination: LimitListView()) {
                            ActionRow(
                                icon: "clock.badge.exclamationmark.fill",
                                color: .orange,
                                title: "Дневные лимиты",
                                subtitle: "Порог времени на день"
                            )
                        }
                        
                        NavigationLink(destination: ParentRewardsDashboardView()) {
                            ActionRow(
                                icon: "trophy.fill",
                                color: .yellow,
                                title: "Задания и награды",
                                subtitle: "Назначить условие и минуты"
                            )
                        }
                        
                        NavigationLink(destination: OptionalFeaturesSettingsView()) {
                            ActionRow(
                                icon: "slider.horizontal.3",
                                color: .purple,
                                title: "Дополнительные опции",
                                subtitle: "Учёба, быстрый код, серии привычек"
                            )
                        }
                        
                        NavigationLink(destination: ScheduleListView()) {
                            ActionRow(
                                icon: "calendar.badge.clock",
                                color: .indigo,
                                title: "Расписания",
                                subtitle: "Сон, школа, уроки"
                            )
                        }
                        
                        // Тумблер защиты от удаления
                        HStack {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.green.opacity(0.12))
                                    .frame(width: 36, height: 36)
                                Image(systemName: "lock.shield.fill")
                                    .foregroundColor(.green)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Защита от удаления")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("Ребёнок не сможет удалить FamilyGuard")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: Binding(
                                get: { managedSettingsService.isChildProtectionActive },
                                set: { enabled in
                                    if enabled {
                                        managedSettingsService.enableChildProtection()
                                    } else {
                                        managedSettingsService.disableChildProtection()
                                    }
                                }
                            ))
                            .labelsHidden()
                        }
                        .padding(14)
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .cornerRadius(14)
                    }
                    
                    // Баннер рекламы (бесплатная модель)
                    BannerView()
                        .frame(height: 50)
                        .padding(.top, 10)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Панель Опекуна")
            .sheet(isPresented: $showAppPicker) {
                AppPickerView(selection: $familyControlsService.activitySelection)
            }
            .sheet(isPresented: $showExtraTimeSheet) {
                GrantExtraTimeSheet()
            }
        }
    }
}

private struct BlockControlCard: View {
    let isBlocked: Bool
    let isLimitSuspended: Bool
    let onToggleBlock: () -> Void
    let onGrantExtraTime: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(isBlocked ? "ALL ACCESS BLOCKED" : (isLimitSuspended ? "ЛИМИТ СНЯТ НА СЕГОДНЯ" : "ДОСТУП РАЗРЕШЁН"))
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(isBlocked ? .red : (isLimitSuspended ? .green : .blue))
                    
                    Text(isBlocked ? "Устройство заблокировано" : "Приложения активны")
                        .font(.title3)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                Image(systemName: isBlocked ? "lock.fill" : "lock.open.fill")
                    .font(.title)
                    .foregroundColor(isBlocked ? .red : .blue)
            }
            
            HStack(spacing: 12) {
                // Кнопка переключения блокировки
                Button(action: onToggleBlock) {
                    Text(isBlocked ? "Разблокировать" : "Заблокировать сейчас")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(isBlocked ? Color.red : Color.blue)
                        .cornerRadius(12)
                }
                
                // Кнопка добавления времени
                Button(action: onGrantExtraTime) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("Продлить")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
                    .frame(width: 120, height: 44)
                    .background(Color.orange.opacity(0.12))
                    .cornerRadius(12)
                }
            }
        }
        .padding(18)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}

private struct NightModeOverrideCard: View {
    let isSuspended: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill((isSuspended ? Color.green : Color.indigo).opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: isSuspended ? "moon.fill" : "moon.zzz.fill")
                    .foregroundColor(isSuspended ? .green : .indigo)
                    .font(.title3)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(isSuspended ? "Разрешено играть ночью" : "Ночной режим сегодня")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(isSuspended ? "Сон отключён только на эту ночь" : "Блокировка включится по расписанию")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: onToggle) {
                Text(isSuspended ? "Включить сон" : "Разрешить")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(isSuspended ? .red : .indigo)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background((isSuspended ? Color.red : Color.indigo).opacity(0.12))
                    .cornerRadius(10)
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}

private struct ActionRow: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                Text(subtitle)
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
        .cornerRadius(14)
    }
}
