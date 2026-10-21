// AppLimit.swift
// FamilyGuard
//
// ЗАЧЕМ ЭТОТ ФАЙЛ:
// Модель данных для дневного лимита экранного времени.

import Foundation

/// Модель конфигурации дневного лимита.
public struct AppLimit: Identifiable, Codable {
    public let id: UUID
    public var name: String
    public var timeLimitMinutes: Int
    public var isEnabled: Bool
    
    public init(id: UUID = UUID(), name: String, timeLimitMinutes: Int, isEnabled: Bool = true) {
        self.id = id
        self.name = name
        self.timeLimitMinutes = timeLimitMinutes
        self.isEnabled = isEnabled
    }
    
    /// Читаемый формат (например "1 ч 30 мин")
    public var formattedDuration: String {
        let hours = timeLimitMinutes / 60
        let minutes = timeLimitMinutes % 60
        if hours > 0 && minutes > 0 {
            return "\(hours) ч \(minutes) мин"
        } else if hours > 0 {
            return "\(hours) ч"
        } else {
            return "\(minutes) мин"
        }
    }
}
