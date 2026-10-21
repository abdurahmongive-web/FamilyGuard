// BlockSchedule.swift
// FamilyGuard
//
// ЗАЧЕМ ЭТОТ ФАЙЛ:
// Модель данных для расписания блокировок (например: Сон, Школа, Уроки).

import Foundation

/// Модель расписания блокировки.
public struct BlockSchedule: Identifiable, Codable {
    public let id: UUID
    public var title: String
    public var startHour: Int
    public var startMinute: Int
    public var endHour: Int
    public var endMinute: Int
    public var isEnabled: Bool
    public var daysOfWeek: [Int] // 1 = Воскресенье, 2 = Понедельник ... 7 = Суббота
    
    public init(
        id: UUID = UUID(),
        title: String,
        startHour: Int,
        startMinute: Int,
        endHour: Int,
        endMinute: Int,
        isEnabled: Bool = true,
        daysOfWeek: [Int] = [1, 2, 3, 4, 5, 6, 7]
    ) {
        self.id = id
        self.title = title
        self.startHour = startHour
        self.startMinute = startMinute
        self.endHour = endHour
        self.endMinute = endMinute
        self.isEnabled = isEnabled
        self.daysOfWeek = daysOfWeek
    }
    
    /// Форматированный интервал (например "22:00 – 07:00")
    public var formattedTimeRange: String {
        let start = String(format: "%02d:%02d", startHour, startMinute)
        let end = String(format: "%02d:%02d", endHour, endMinute)
        return "\(start) – \(end)"
    }
}
