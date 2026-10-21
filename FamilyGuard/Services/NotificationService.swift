// NotificationService.swift
// FamilyGuard
//
// ЗАЧЕМ ЭТОТ ФАЙЛ:
// Отвечает за системные уведомления для опекуна и ребёнка
// (например: "Осталось 10 минут до сна", "Дневной лимит исчерпан").

import Foundation
import UserNotifications

public final class NotificationService {
    
    public static let shared = NotificationService()
    
    private init() {}
    
    public func requestAuthorization() async -> Bool {
        do {
            let options: UNAuthorizationOptions = [.alert, .sound, .badge]
            return try await UNUserNotificationCenter.current().requestAuthorization(options: options)
        } catch {
            print("❌ [NotificationService] Ошибка запроса уведомлений: \(error)")
            return false
        }
    }
    
    public func sendNotification(title: String, body: String, timeInterval: TimeInterval = 1) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(timeInterval, 1), repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ [NotificationService] Не удалось отправить пуш: \(error)")
            }
        }
    }
}
