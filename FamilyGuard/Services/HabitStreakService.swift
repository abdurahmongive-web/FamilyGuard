// HabitStreakService.swift
// FamilyGuard
//
// ЗАЧЕМ ЭТОТ ФАЙЛ:
// Сервис подсчёта серии хороших привычек ребёнка (Streak).
// Если ребёнок провёл день без нарушений, серия растёт,
// а в конце недели он получает бейдж и бонусное время.

import Foundation
import Combine

public final class HabitStreakService: ObservableObject {
    
    public static let shared = HabitStreakService()
    
    private let storageKey = "familyguard.habitStreak"
    
    @Published public var streak: HabitStreak = HabitStreak()
    
    private init() {
        loadStreak()
    }
    
    public func recordCleanDay() {
        streak.currentStreakDays += 1
        if streak.currentStreakDays > streak.bestStreakDays {
            streak.bestStreakDays = streak.currentStreakDays
        }
        streak.lastRecordedDate = Date()
        
        // Открытие бейджей
        if streak.currentStreakDays >= 7 && !streak.unlockedBadges.contains("week_champion") {
            streak.unlockedBadges.append("week_champion")
        }
        saveStreak()
        print("🔥 [HabitStreakService] Серия увеличена: \(streak.currentStreakDays) дней!")
    }
    
    private func saveStreak() {
        if let data = try? JSONEncoder().encode(streak) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    private func loadStreak() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let loaded = try? JSONDecoder().decode(HabitStreak.self, from: data) else {
            return
        }
        self.streak = loaded
    }
}
