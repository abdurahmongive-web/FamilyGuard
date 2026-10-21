// ExtraTimeOption.swift
// FamilyGuard
//
// ЗАЧЕМ ЭТОТ ФАЙЛ:
// Модель вариантов продления экранного времени опекуном
// (+15м, +30м, +1ч, +2ч, +3ч или полное снятие лимита на сегодня).

import Foundation

public enum ExtraTimeOption: Identifiable, CaseIterable {
    case minutes15
    case minutes30
    case hour1
    case hours2
    case hours3
    case unlimitedToday
    
    public var id: String { title }
    
    public var title: String {
        switch self {
        case .minutes15: return "+15 минут"
        case .minutes30: return "+30 минут"
        case .hour1: return "+1 час"
        case .hours2: return "+2 часа"
        case .hours3: return "+3 часа"
        case .unlimitedToday: return "Снять лимит до конца дня"
        }
    }
    
    public var minutes: Int {
        switch self {
        case .minutes15: return 15
        case .minutes30: return 30
        case .hour1: return 60
        case .hours2: return 120
        case .hours3: return 180
        case .unlimitedToday: return -1 // Специальное значение
        }
    }
    
    public var icon: String {
        switch self {
        case .minutes15, .minutes30: return "clock.badge.plus"
        case .hour1, .hours2, .hours3: return "hourglass.badge.plus"
        case .unlimitedToday: return "infinity.circle.fill"
        }
    }
}
