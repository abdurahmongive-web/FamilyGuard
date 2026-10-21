// LocalizationManager.swift
// FamilyGuard
//
// ЗАЧЕМ ЭТОТ ФАЙЛ:
// Управляет языками интерфейса приложения (Русский и English).
// Позволяет мгновенно переключать язык в настройках приложения
// либо автоматически использовать системный язык устройства.

import Foundation
import SwiftUI
import Combine

public enum AppLanguage: String, CaseIterable, Identifiable {
    case russian = "ru"
    case english = "en"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .russian: return "Русский 🇷🇺"
        case .english: return "English 🇺🇸"
        }
    }
}

public final class LocalizationManager: ObservableObject {
    
    public static let shared = LocalizationManager()
    
    private let languageKey = "familyguard.selectedLanguage"
    
    @Published public var currentLanguage: AppLanguage = .russian
    
    private init() {
        if let savedLang = UserDefaults.standard.string(forKey: languageKey),
           let lang = AppLanguage(rawValue: savedLang) {
            self.currentLanguage = lang
        } else {
            // Определение языка системы
            let preferred = Locale.preferredLanguages.first ?? "ru"
            self.currentLanguage = preferred.starts(with: "ru") ? .russian : .english
        }
    }
    
    public func setLanguage(_ lang: AppLanguage) {
        self.currentLanguage = lang
        UserDefaults.standard.set(lang.rawValue, forKey: languageKey)
    }
    
    /// Возвращает локализованный текст по ключу
    public func string(for key: String) -> String {
        let isRu = currentLanguage == .russian
        switch key {
        // Главный экран опекуна
        case "parent_dashboard_title": return isRu ? "Панель Опекуна" : "Guardian Dashboard"
        case "block_now": return isRu ? "Заблокировать сейчас" : "Block Now"
        case "unblock": return isRu ? "Разблокировать" : "Unblock"
        case "all_access_blocked": return isRu ? "ДОСТУП ЗАБЛОКИРОВАН" : "ALL ACCESS BLOCKED"
        case "access_granted": return isRu ? "ДОСТУП РАЗРЕШЁН" : "ACCESS GRANTED"
        case "grant_extra_time": return isRu ? "Продлить время" : "Grant Time"
        case "allow_night_play": return isRu ? "Разрешить играть ночью" : "Allow Playing Tonight"
        case "night_mode_active": return isRu ? "Ночной режим активен" : "Night Mode Active"
        
        // Лимиты и расписания
        case "daily_limits": return isRu ? "Дневные лимиты" : "Daily Limits"
        case "schedules": return isRu ? "Расписания" : "Schedules"
        case "child_protection": return isRu ? "Защита от удаления" : "Anti-Removal Protection"
        
        // Задания и награды
        case "chores_and_rewards": return isRu ? "Задания и награды" : "Quests & Rewards"
        case "create_chore": return isRu ? "Создать задание" : "Create Quest"
        case "chore_condition": return isRu ? "Условие задания" : "Task Description"
        case "reward_minutes": return isRu ? "Награда (в минутах)" : "Reward (minutes)"
        case "approve_reward": return isRu ? "Одобрить и наградить" : "Approve & Reward"
        case "waiting_approval": return isRu ? "Ждёт подтверждения" : "Waiting Approval"
        case "i_did_it": return isRu ? "Я выполнил!" : "I Did It!"
        
        // Экран ребёнка
        case "child_dashboard_title": return isRu ? "Моё время" : "My Screen Time"
        case "have_a_great_day": return isRu ? "Отличного дня!" : "Have a Great Day!"
        case "available_time": return isRu ? "Доступное время для игр" : "Available Gaming Time"
        case "status_normal": return isRu ? "В норме" : "Safe & Sound"
        case "emergency_recovery": return isRu ? "Экстренное восстановление" : "Emergency Recovery"
            
        default: return key
        }
    }
}

public extension String {
    var localized: String {
        LocalizationManager.shared.string(for: self)
    }
}
