// Constants.swift
// FamilyGuard
//
// ЗАЧЕМ ЭТОТ ФАЙЛ:
// Хранит все глобальные идентификаторы и строковые константы проекта.
// Использование единых констант предотвращает опечатки и гарантирует,
// что основное приложение и системные расширения обращаются к одним и тем же ключам.

import Foundation
import DeviceActivity
import ManagedSettings

public enum Constants {
    
    // MARK: - App Group Identifier
    
    /// Идентификатор общей группы для обмена данными между приложением и расширениями.
    /// Этот же идентификатор должен быть указан в Signing & Capabilities -> App Groups в Xcode.
    public static let appGroupID = "group.com.familyguard.shared"
    
    // MARK: - Storage Keys (UserDefaults)
    
    public enum StorageKeys {
        public static let userRole = "familyguard.userRole"
        public static let hasCompletedOnboarding = "familyguard.hasCompletedOnboarding"
        public static let activitySelection = "familyguard.activitySelection"
        public static let dailyLimits = "familyguard.dailyLimits"
        public static let schedules = "familyguard.schedules"
        public static let isBlockNowActive = "familyguard.isBlockNowActive"
        public static let isChildProtectionEnabled = "familyguard.isChildProtectionEnabled"
    }
}

// MARK: - ManagedSettingsStore Names

extension ManagedSettingsStore.Name {
    /// Хранилище блокировок по дневному лимиту
    public static let dailyLimit = ManagedSettingsStore.Name("DailyLimitStore")
    
    /// Хранилище блокировок по расписанию (школа, сон)
    public static let schedule = ManagedSettingsStore.Name("ScheduleStore")
    
    /// Хранилище для мгновенной блокировки по кнопке
    public static let blockNow = ManagedSettingsStore.Name("BlockNowStore")
    
    /// Хранилище защитных системных правил (запрет удаления и т.д.)
    public static let protection = ManagedSettingsStore.Name("ProtectionStore")
}

// MARK: - DeviceActivity Names

extension DeviceActivityName {
    /// Имя активности для мониторинга дневного лимита
    public static let dailyLimitActivity = DeviceActivityName("com.familyguard.dailyLimitActivity")
    
    /// Имя активности для мониторинга расписания
    public static let scheduleActivity = DeviceActivityName("com.familyguard.scheduleActivity")
}

// MARK: - DeviceActivityEvent Names

extension DeviceActivityEvent.Name {
    /// Событие достижения порога дневного лимита
    public static let dailyLimitThreshold = DeviceActivityEvent.Name("com.familyguard.dailyLimitThreshold")
    
    /// Событие предупреждения перед лимитом (например, за 10 минут)
    public static let dailyLimitWarning = DeviceActivityEvent.Name("com.familyguard.dailyLimitWarning")
}
