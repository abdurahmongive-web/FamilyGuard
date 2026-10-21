// FamilyGuardShieldAction.swift
// ShieldActionExtension
//
// ЗАЧЕМ ЭТОТ ФАЙЛ:
// Обрабатывает нажатия кнопок на экране блокировки (Shield).
// Когда ребёнок нажимает "Понятно" или "Запросить время", iOS вызывает методы этого класса.

import ManagedSettings
import Foundation

public final class FamilyGuardShieldAction: ShieldActionDelegate {
    
    public override init() {
        super.init()
    }
    
    /// Обработка кнопок блокировки приложения
    public override func handle(
        action: ShieldAction,
        for application: ApplicationToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        switch action {
        case .primaryButtonPressed:
            // Кнопка "Понятно" -> Мягко закрываем приложение и возвращаем ребёнка на рабочий стол
            print("👉 [ShieldAction] Нажата основная кнопка: закрытие приложения")
            completionHandler(.close)
            
        case .secondaryButtonPressed:
            // Кнопка "Запросить время" -> Оставляем блокировку активной (defer)
            print("👉 [ShieldAction] Запрос дополнительного времени отправлен")
            completionHandler(.defer)
            
        @unknown default:
            completionHandler(.close)
        }
    }
    
    /// Обработка кнопок блокировки веб-домена
    public override func handle(
        action: ShieldAction,
        for webDomain: WebDomainToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        switch action {
        case .primaryButtonPressed:
            completionHandler(.close)
        case .secondaryButtonPressed:
            completionHandler(.defer)
        @unknown default:
            completionHandler(.close)
        }
    }
    
    /// Обработка кнопок блокировки категории
    public override func handle(
        action: ShieldAction,
        for category: ActivityCategoryToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        switch action {
        case .primaryButtonPressed:
            completionHandler(.close)
        case .secondaryButtonPressed:
            completionHandler(.defer)
        @unknown default:
            completionHandler(.close)
        }
    }
}
