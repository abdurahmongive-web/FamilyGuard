// DeviceActivityService.swift
// FamilyGuard
//
// ЗАЧЕМ ЭТОТ ФАЙЛ:
// Запускает и останавливает мониторинг экранного времени через DeviceActivityCenter.
// Система сама отслеживает время и будит наше расширение DeviceActivityMonitorExtension.

import Foundation
import DeviceActivity
import FamilyControls

public final class DeviceActivityService {
    
    public static let shared = DeviceActivityService()
    
    private let center = DeviceActivityCenter()
    
    private init() {}
    
    /// Запуск мониторинга дневного лимита
    public func startDailyLimitMonitoring(minutes: Int, selection: FamilyActivitySelection) {
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )
        
        let threshold = DateComponents(minute: minutes)
        let event = DeviceActivityEvent(
            applications: selection.applicationTokens,
            categories: selection.categoryTokens,
            webDomains: selection.webDomainTokens,
            threshold: threshold
        )
        
        do {
            try center.startMonitoring(
                .dailyLimitActivity,
                during: schedule,
                events: [.dailyLimitThreshold: event]
            )
            print("✅ [DeviceActivityService] Мониторинг дневного лимита запущен на \(minutes) мин")
        } catch {
            print("❌ [DeviceActivityService] Ошибка старта мониторинга лимита: \(error)")
        }
    }
    
    /// Запуск мониторинга расписания (например Сон или Школа)
    public func startScheduleMonitoring(schedule: BlockSchedule) {
        let activitySchedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: schedule.startHour, minute: schedule.startMinute),
            intervalEnd: DateComponents(hour: schedule.endHour, minute: schedule.endMinute),
            repeats: true
        )
        
        do {
            try center.startMonitoring(
                .scheduleActivity,
                during: activitySchedule
            )
            print("✅ [DeviceActivityService] Мониторинг расписания запущен: \(schedule.title)")
        } catch {
            print("❌ [DeviceActivityService] Ошибка старта расписания: \(error)")
        }
    }
    
    /// Остановка всех активностей мониторинга
    public func stopAllMonitoring() {
        center.stopMonitoring([.dailyLimitActivity, .scheduleActivity])
        print("⏹️ [DeviceActivityService] Мониторинг остановлен")
    }
}
