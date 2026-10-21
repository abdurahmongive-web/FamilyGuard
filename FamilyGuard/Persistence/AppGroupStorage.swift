// AppGroupStorage.swift
// FamilyGuard
//
// ЗАЧЕМ ЭТОТ ФАЙЛ:
// Мост между основным приложением и фоновыми системными расширениями.
// Хранит состояние блокировок, расписаний, бонусного времени и настроек на сегодняшнюю ночь.

import Foundation
import FamilyControls

final class AppGroupStorage {
    
    static let shared = AppGroupStorage()
    
    private let sharedDefaults: UserDefaults?
    
    private enum Keys {
        static let selectedActivities = "familyguard.selectedActivities"
        static let userRole = "familyguard.userRole"
        static let hasCompletedOnboarding = "familyguard.hasCompletedOnboarding"
        static let isBlockNowActive = "familyguard.isBlockNowActive"
        static let childProtectionEnabled = "familyguard.childProtectionEnabled"
        static let isBedtimeSuspendedTonight = "familyguard.isBedtimeSuspendedTonight"
        static let isDailyLimitSuspendedToday = "familyguard.isDailyLimitSuspendedToday"
        static let bonusTimeExpiration = "familyguard.bonusTimeExpiration"
        static let limitsConfig = "familyguard.limitsConfig"
        static let schedulesConfig = "familyguard.schedulesConfig"
    }
    
    private init() {
        self.sharedDefaults = UserDefaults(suiteName: "group.com.familyguard.shared")
    }
    
    
    // MARK: - Limits
    func saveLimits(_ limits: [AppLimit]) {
        if let data = try? PropertyListEncoder().encode(limits) {
            sharedDefaults?.set(data, forKey: Keys.limitsConfig)
        }
    }
    
    func loadLimits() -> [AppLimit] {
        guard let data = sharedDefaults?.data(forKey: Keys.limitsConfig) else { return [] }
        return (try? PropertyListDecoder().decode([AppLimit].self, from: data)) ?? []
    }

    // MARK: - Selection
    
    func saveSelection(_ selection: FamilyActivitySelection) {
        if let data = try? PropertyListEncoder().encode(selection) {
            sharedDefaults?.set(data, forKey: Keys.selectedActivities)
        }
    }
    
    func loadSelection() -> FamilyActivitySelection? {
        guard let data = sharedDefaults?.data(forKey: Keys.selectedActivities) else { return nil }
        return try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: data)
    }
    
    func clearSelection() {
        sharedDefaults?.removeObject(forKey: Keys.selectedActivities)
    }
    
    // MARK: - User Role & Onboarding
    
    func saveUserRole(_ role: String) {
        sharedDefaults?.set(role, forKey: Keys.userRole)
    }
    
    func loadUserRole() -> String? {
        sharedDefaults?.string(forKey: Keys.userRole)
    }
    
    func setOnboardingCompleted() {
        sharedDefaults?.set(true, forKey: Keys.hasCompletedOnboarding)
    }
    
    func hasCompletedOnboarding() -> Bool {
        sharedDefaults?.bool(forKey: Keys.hasCompletedOnboarding) ?? false
    }
    
    // MARK: - Block Now & Protection
    
    func setBlockNowActive(_ isActive: Bool) {
        sharedDefaults?.set(isActive, forKey: Keys.isBlockNowActive)
    }
    
    func isBlockNowActive() -> Bool {
        sharedDefaults?.bool(forKey: Keys.isBlockNowActive) ?? false
    }
    
    func setChildProtectionEnabled(_ enabled: Bool) {
        sharedDefaults?.set(enabled, forKey: Keys.childProtectionEnabled)
    }
    
    func isChildProtectionEnabled() -> Bool {
        sharedDefaults?.bool(forKey: Keys.childProtectionEnabled) ?? false
    }
    
    // MARK: - Bedtime Tonight Suspension (Отключение сна на сегодня)
    
    func setBedtimeSuspendedTonight(_ suspended: Bool) {
        sharedDefaults?.set(suspended, forKey: Keys.isBedtimeSuspendedTonight)
    }
    
    func isBedtimeSuspendedTonight() -> Bool {
        sharedDefaults?.bool(forKey: Keys.isBedtimeSuspendedTonight) ?? false
    }
    
    // MARK: - Bonus Extra Time (Продление времени)
    
    func setBonusTimeExpiration(_ date: Date?) {
        sharedDefaults?.set(date, forKey: Keys.bonusTimeExpiration)
    }
    
    func getBonusTimeExpiration() -> Date? {
        sharedDefaults?.object(forKey: Keys.bonusTimeExpiration) as? Date
    }
    
    func setDailyLimitSuspendedToday(_ suspended: Bool) {
        sharedDefaults?.set(suspended, forKey: Keys.isDailyLimitSuspendedToday)
    }
    
    func isDailyLimitSuspendedToday() -> Bool {
        sharedDefaults?.bool(forKey: Keys.isDailyLimitSuspendedToday) ?? false
    }
    
    // MARK: - Schedules & Limits
    
    func saveSchedules(_ schedules: [BlockSchedule]) {
        if let data = try? PropertyListEncoder().encode(schedules) {
            sharedDefaults?.set(data, forKey: Keys.schedulesConfig)
        }
    }
    
    func loadSchedules() -> [BlockSchedule] {
        guard let data = sharedDefaults?.data(forKey: Keys.schedulesConfig) else { return [] }
        return (try? PropertyListDecoder().decode([BlockSchedule].self, from: data)) ?? []
    }
}
