// FamilyGuardMonitor.swift
// DeviceActivityMonitorExtension
//
// Фоновый системный сторож.
// Автоматически обрабатывает расписания и лимиты.
// Учитывает статус "Отключить сон на сегодня" (isBedtimeSuspendedTonight).

import DeviceActivity
import ManagedSettings
import FamilyControls
import Foundation
import UserNotifications

// MARK: - Локальные расширения для имен хранилищ
private extension ManagedSettingsStore.Name {
    static let dailyLimit = ManagedSettingsStore.Name("dailyLimit")
    static let schedule = ManagedSettingsStore.Name("schedule")
}

// MARK: - Локальный доступ к AppGroup (без внешних зависимостей)
private enum MonitorStorage {
    static let suiteName = "group.com.familyguard.shared"
    
    static var defaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }
    
    static func isBedtimeSuspendedTonight() -> Bool {
        defaults?.bool(forKey: "familyguard.isBedtimeSuspendedTonight") ?? false
    }
    
    static func setBedtimeSuspendedTonight(_ value: Bool) {
        defaults?.set(value, forKey: "familyguard.isBedtimeSuspendedTonight")
    }
    
    static func isDailyLimitSuspendedToday() -> Bool {
        defaults?.bool(forKey: "familyguard.isDailyLimitSuspendedToday") ?? false
    }
    
    static func setDailyLimitSuspendedToday(_ value: Bool) {
        defaults?.set(value, forKey: "familyguard.isDailyLimitSuspendedToday")
    }
    
    static func loadSelection() -> FamilyActivitySelection? {
        guard let data = defaults?.data(forKey: "familyguard.selectedActivities") else { return nil }
        return try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: data)
    }
}

// MARK: - Основной монитор активности
public final class FamilyGuardMonitor: DeviceActivityMonitor {
    
    private let dailyLimitStore = ManagedSettingsStore(named: .dailyLimit)
    private let scheduleStore = ManagedSettingsStore(named: .schedule)
    
    // MARK: - Interval Lifecycle (Расписания блокировок)
    
    public override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        
        // ПРОВЕРКА: Разрешил ли родитель играть этой ночью?
        if MonitorStorage.isBedtimeSuspendedTonight() {
            print("🌙 [FamilyGuardMonitor] Ночной режим ПРОПУЩЕН на эту ночь по разрешению опекуна.")
            return
        }
        
        if let selection = MonitorStorage.loadSelection() {
            if !selection.applicationTokens.isEmpty {
                scheduleStore.shield.applications = selection.applicationTokens
            }
            if !selection.categoryTokens.isEmpty {
                scheduleStore.shield.applicationCategories = .specific(selection.categoryTokens)
            }
            if !selection.webDomainTokens.isEmpty {
                scheduleStore.shield.webDomains = selection.webDomainTokens
            }
            print("🔒 [FamilyGuardMonitor] Щит расписания применён")
        }
    }
    
    public override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        
        // Снимаем блокировку расписания утром
        scheduleStore.clearAllSettings()
        
        // Сбрасываем разрешение на пропуск сна, чтобы следующей ночью расписание снова работало!
        MonitorStorage.setBedtimeSuspendedTonight(false)
        MonitorStorage.setDailyLimitSuspendedToday(false)
        
        print("☀️ [FamilyGuardMonitor] Утро наступило: расписание сна и лимиты сброшены на новый день")
    }
    
    // MARK: - Event Lifecycle (Лимиты)
    
    public override func eventDidReachThreshold(
        _ event: DeviceActivityEvent.Name,
        activity: DeviceActivityName
    ) {
        super.eventDidReachThreshold(event, activity: activity)
        
        // Если лимит снят на сегодня — не блокируем
        if MonitorStorage.isDailyLimitSuspendedToday() {
            print("ℹ️ [FamilyGuardMonitor] Дневной лимит достигнут, но снят родителем на сегодня")
            return
        }
        
        if let selection = MonitorStorage.loadSelection() {
            if !selection.applicationTokens.isEmpty {
                dailyLimitStore.shield.applications = selection.applicationTokens
            }
            if !selection.categoryTokens.isEmpty {
                dailyLimitStore.shield.applicationCategories = .specific(selection.categoryTokens)
            }
            if !selection.webDomainTokens.isEmpty {
                dailyLimitStore.shield.webDomains = selection.webDomainTokens
            }
            print("🔒 [FamilyGuardMonitor] Щит дневного лимита активирован")
        }
    }
    
    // MARK: - Warnings
    
    public override func intervalWillStartWarning(for activity: DeviceActivityName) {
        super.intervalWillStartWarning(for: activity)
        if !MonitorStorage.isBedtimeSuspendedTonight() {
            sendLocalWarning(title: "Скоро отход ко сну", body: "Через 15 минут устройства будут переведены в ночной режим.")
        }
    }
    
    public override func eventWillReachThresholdWarning(
        _ event: DeviceActivityEvent.Name,
        activity: DeviceActivityName
    ) {
        super.eventWillReachThresholdWarning(event, activity: activity)
        sendLocalWarning(title: "Осталось мало времени", body: "У вас осталось 10 минут доступного времени.")
    }
    
    private func sendLocalWarning(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
}
