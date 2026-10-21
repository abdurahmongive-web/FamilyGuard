// HabitStreak.swift
// FamilyGuard
//
// ЗАЧЕМ ЭТОТ ФАЙЛ:
// Модель данных для геймификации и серии хороших привычек (Streak).
// Считает дни без превышения лимитов и нарушений режима сна.

import Foundation

public struct HabitStreak: Codable {
    public var currentStreakDays: Int
    public var bestStreakDays: Int
    public var lastRecordedDate: Date?
    public var unlockedBadges: [String]
    
    public init(
        currentStreakDays: Int = 3,
        bestStreakDays: Int = 7,
        lastRecordedDate: Date? = Date(),
        unlockedBadges: [String] = ["first_step", "three_days"]
    ) {
        self.currentStreakDays = currentStreakDays
        self.bestStreakDays = bestStreakDays
        self.lastRecordedDate = lastRecordedDate
        self.unlockedBadges = unlockedBadges
    }
}
