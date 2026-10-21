// ParentalSettings.swift
// FamilyGuard
//
// ЗАЧЕМ ЭТОТ ФАЙЛ:
// Модель настроек дополнительных и опциональных функций опекуна:
// - Режим фокуса на учёбе (опционально)
// - Быстрый 4-значный код на детском телефоне (опционально)
// - Серия привычек (Streak) и бейджи (опционально)

import Foundation

public struct ParentalSettings: Codable {
    /// Опция 1: Включен ли режим фокуса на учёбе
    public var isStudyFocusEnabled: Bool
    
    /// Опция 3: Разрешён ли быстрый ввод 4-значного кода опекуна на телефоне ребёнка
    public var isQuickPasscodeEnabled: Bool
    public var quickPasscodeHash: String
    
    /// Опция 4: Включена ли геймификация и серия хороших привычек (Streak)
    public var isHabitStreakEnabled: Bool
    public var weekendBonusMinutesForStreak: Int
    
    public init(
        isStudyFocusEnabled: Bool = false,
        isQuickPasscodeEnabled: Bool = true,
        quickPasscodeHash: String = "",
        isHabitStreakEnabled: Bool = true,
        weekendBonusMinutesForStreak: Int = 30
    ) {
        self.isStudyFocusEnabled = isStudyFocusEnabled
        self.isQuickPasscodeEnabled = isQuickPasscodeEnabled
        self.quickPasscodeHash = quickPasscodeHash
        self.isHabitStreakEnabled = isHabitStreakEnabled
        self.weekendBonusMinutesForStreak = weekendBonusMinutesForStreak
    }
}
