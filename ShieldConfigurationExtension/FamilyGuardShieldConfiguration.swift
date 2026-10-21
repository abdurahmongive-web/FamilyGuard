// FamilyGuardShieldConfiguration.swift
// ShieldConfigurationExtension
//
// ЗАЧЕМ ЭТОТ ФАЙЛ:
// Кастомизирует внешний вид нативного экрана блокировки Apple (Shield).
// Когда ребёнок нажимает на заблокированное приложение, iOS показывает этот интерфейс:
// заголовок, текст пояснения, цвета и логотип FamilyGuard.

import ManagedSettingsUI
import ManagedSettings
import UIKit

public final class FamilyGuardShieldConfiguration: ShieldConfigurationDataSource {
    
    public override init() {
        super.init()
    }
    
    /// Настройка экрана блокировки для отдельного приложения
    public override func configuration(shielding application: Application) -> ShieldConfiguration {
        return createShield(
            title: "Время вышло",
            subtitle: "Опекун ограничил доступ к этому приложению через FamilyGuard."
        )
    }
    
    /// Настройка экрана блокировки для приложения внутри категории (например, Игры)
    public override func configuration(
        shielding application: Application,
        in category: ActivityCategory
    ) -> ShieldConfiguration {
        return createShield(
            title: "Категория заблокирована",
            subtitle: "Лимит времени для этой категории исчерпан."
        )
    }
    
    /// Настройка экрана блокировки для веб-сайта в Safari
    public override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        return createShield(
            title: "Сайт заблокирован",
            subtitle: "Доступ к этому веб-ресурсу ограничен настройками родительского контроля."
        )
    }
    
    /// Настройка экрана блокировки для веб-сайта в категории
    public override func configuration(
        shielding webDomain: WebDomain,
        in category: ActivityCategory
    ) -> ShieldConfiguration {
        return createShield(
            title: "Доступ ограничен",
            subtitle: "Веб-страница заблокирована расписанием FamilyGuard."
        )
    }
    
    // MARK: - Вспомогательный конструктор экрана Shield
    
    private func createShield(title: String, subtitle: String) -> ShieldConfiguration {
        let icon = UIImage(systemName: "person.badge.shield.checkmark.fill") ?? UIImage()
        
        return ShieldConfiguration(
            backgroundBlurStyle: .systemMaterial,
            backgroundColor: UIColor.systemBackground,
            icon: icon,
            title: ShieldConfiguration.Label(text: title, color: .label),
            subtitle: ShieldConfiguration.Label(text: subtitle, color: .secondaryLabel),
            primaryButtonLabel: ShieldConfiguration.Label(text: "Понятно", color: .white),
            primaryButtonBackgroundColor: UIColor.systemBlue,
            secondaryButtonLabel: ShieldConfiguration.Label(text: "Запросить время", color: .systemBlue)
        )
    }
}
