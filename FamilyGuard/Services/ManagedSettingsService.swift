// ManagedSettingsService.swift
// FamilyGuard
//
// ЗАЧЕМ ЭТОТ ФАЙЛ:
// Сервис управления блокировками через ManagedSettingsStore.
// Включает новые функции:
// 1. Продление времени (+15м, +30м, +1-3 часа или полное снятие лимита на сегодня).
// 2. Пропуск ночного режима на сегодня (разрешение играть ночью без удаления расписания).

import Foundation
import ManagedSettings
import FamilyControls

@MainActor
public final class ManagedSettingsService: ObservableObject {
    
    public static let shared = ManagedSettingsService()
    
    // Хранилища правил Apple
    private let dailyLimitStore = ManagedSettingsStore(named: .dailyLimit)
    private let scheduleStore = ManagedSettingsStore(named: .schedule)
    private let blockNowStore = ManagedSettingsStore(named: .blockNow)
    private let protectionStore = ManagedSettingsStore(named: .protection)
    
    @Published public var isBlockNowActive: Bool = false
    @Published public var isChildProtectionActive: Bool = false
    @Published public var isBedtimeSuspendedTonight: Bool = false
    @Published public var isDailyLimitSuspendedToday: Bool = false
    @Published public var bonusTimeRemainingMinutes: Int = 0
    
    private init() {
        self.isBlockNowActive = AppGroupStorage.shared.isBlockNowActive()
        self.isChildProtectionActive = AppGroupStorage.shared.isChildProtectionEnabled()
        self.isBedtimeSuspendedTonight = AppGroupStorage.shared.isBedtimeSuspendedTonight()
        self.isDailyLimitSuspendedToday = AppGroupStorage.shared.isDailyLimitSuspendedToday()
    }
    
    // MARK: - Block Now (Мгновенная блокировка)
    
    public func blockNow(selection: FamilyActivitySelection) {
        if !selection.applicationTokens.isEmpty {
            blockNowStore.shield.applications = selection.applicationTokens
        }
        if !selection.categoryTokens.isEmpty {
            blockNowStore.shield.applicationCategories = .specific(selection.categoryTokens)
        }
        if !selection.webDomainTokens.isEmpty {
            blockNowStore.shield.webDomains = selection.webDomainTokens
        }
        
        isBlockNowActive = true
        AppGroupStorage.shared.setBlockNowActive(true)
    }
    
    public func unblock() {
        blockNowStore.clearAllSettings()
        isBlockNowActive = false
        AppGroupStorage.shared.setBlockNowActive(false)
    }
    
    // MARK: - Bonus Time (+15м, +30м, +1ч, +2ч, +3ч)
    
    /// Выдаёт ребёнку бонусное дополнительное время сверх лимита
    public func grantBonusTime(minutes: Int) {
        // Снимаем текущую блокировку дневного лимита
        dailyLimitStore.clearAllSettings()
        bonusTimeRemainingMinutes = minutes
        
        let expireDate = Date().addingTimeInterval(TimeInterval(minutes * 60))
        AppGroupStorage.shared.setBonusTimeExpiration(expireDate)
        
        print("🎁 [ManagedSettingsService] Выдано бонусное время: +\(minutes) минут (до \(expireDate))")
        
        // Запускаем таймер возврата блокировки по истечении времени
        Task {
            try? await Task.sleep(nanoseconds: UInt64(minutes) * 60 * 1_000_000_000)
            await reapplyLimitAfterBonus()
        }
    }
    
    /// Полное снятие лимита до конца сегодняшнего дня
    public func removeDailyLimitForToday() {
        dailyLimitStore.clearAllSettings()
        isDailyLimitSuspendedToday = true
        AppGroupStorage.shared.setDailyLimitSuspendedToday(true)
        print("🔓 [ManagedSettingsService] Дневной лимит полностью снят на сегодня!")
    }
    
    private func reapplyLimitAfterBonus() {
        // Если родитель не снял лимит до конца дня, возвращаем щит
        if !isDailyLimitSuspendedToday {
            if let selection = AppGroupStorage.shared.loadSelection() {
                applyDailyLimitShield(selection: selection)
            }
        }
        bonusTimeRemainingMinutes = 0
        AppGroupStorage.shared.setBonusTimeExpiration(nil)
        print("⏰ [ManagedSettingsService] Бонусное время истекло. Блокировка возвращена.")
    }
    
    // MARK: - Skip Bedtime Tonight (Отключение сна на эту ночь)
    
    /// Переключает ночной режим на сегодняшнюю ночь
    public func toggleBedtimeForTonight() {
        setBedtimeSuspendedTonight(!isBedtimeSuspendedTonight)
    }
    
    public func setBedtimeSuspendedTonight(_ suspend: Bool) {
        isBedtimeSuspendedTonight = suspend
        AppGroupStorage.shared.setBedtimeSuspendedTonight(suspend)
        
        if suspend {
            // Если сон отключен на сегодня — немедленно снимаем блокировку расписания
            scheduleStore.clearAllSettings()
            print("🌙 [ManagedSettingsService] Ночной режим ОТКЛЮЧЁН на эту ночь. Ребёнок может играть!")
        } else {
            // Если включен обратно — восстанавливаем блокировку
            if let selection = AppGroupStorage.shared.loadSelection() {
                applyScheduleShield(selection: selection)
            }
            print("🌙 [ManagedSettingsService] Ночной режим ВОССТАНОВЛЕН на эту ночь.")
        }
    }
    
    // MARK: - Daily Limits & Schedules
    
    public func applyDailyLimitShield(selection: FamilyActivitySelection) {
        guard !isDailyLimitSuspendedToday else { return }
        
        if !selection.applicationTokens.isEmpty {
            dailyLimitStore.shield.applications = selection.applicationTokens
        }
        if !selection.categoryTokens.isEmpty {
            dailyLimitStore.shield.applicationCategories = .specific(selection.categoryTokens)
        }
        if !selection.webDomainTokens.isEmpty {
            dailyLimitStore.shield.webDomains = selection.webDomainTokens
        }
    }
    
    public func removeDailyLimitShield() {
        dailyLimitStore.clearAllSettings()
    }
    
    public func applyScheduleShield(selection: FamilyActivitySelection) {
        guard !isBedtimeSuspendedTonight else {
            print("🌙 [ManagedSettingsService] Расписание пропущено: активен режим разрешения на сегодня")
            return
        }
        
        if !selection.applicationTokens.isEmpty {
            scheduleStore.shield.applications = selection.applicationTokens
        }
        if !selection.categoryTokens.isEmpty {
            scheduleStore.shield.applicationCategories = .specific(selection.categoryTokens)
        }
        if !selection.webDomainTokens.isEmpty {
            scheduleStore.shield.webDomains = selection.webDomainTokens
        }
    }
    
    public func removeScheduleShield() {
        scheduleStore.clearAllSettings()
    }
    
    // MARK: - Child Protection
    
    public func enableChildProtection() {
        protectionStore.application.denyAppRemoval = true
        protectionStore.application.denyAppInstallation = true
        protectionStore.dateAndTime.requireAutomaticDateAndTime = true
        protectionStore.passcode.lockPasscode = true
        protectionStore.account.lockAccounts = true
        
        isChildProtectionActive = true
        AppGroupStorage.shared.setChildProtectionEnabled(true)
    }
    
    public func disableChildProtection() {
        protectionStore.clearAllSettings()
        isChildProtectionActive = false
        AppGroupStorage.shared.setChildProtectionEnabled(false)
    }
    
    public func removeAllRestrictions() {
        dailyLimitStore.clearAllSettings()
        scheduleStore.clearAllSettings()
        blockNowStore.clearAllSettings()
        protectionStore.clearAllSettings()
        
        isBlockNowActive = false
        isChildProtectionActive = false
        isDailyLimitSuspendedToday = false
        isBedtimeSuspendedTonight = false
        
        AppGroupStorage.shared.setBlockNowActive(false)
        AppGroupStorage.shared.setChildProtectionEnabled(false)
        AppGroupStorage.shared.setDailyLimitSuspendedToday(false)
        AppGroupStorage.shared.setBedtimeSuspendedTonight(false)
        AppGroupStorage.shared.setBonusTimeExpiration(nil)
    }
}
