// UserRole.swift
// FamilyGuard
//
// ЗАЧЕМ ЭТОТ ФАЙЛ:
// Определяет две роли в приложении: Родитель/Опекун и Ребёнок.
// От выбранной роли зависит, какой интерфейс увидит пользователь.

import Foundation

/// Роль пользователя в приложении.
///
/// РОДИТЕЛЬ видит:
/// - Dashboard с информацией об использовании
/// - Управление лимитами
/// - Управление расписаниями
/// - Кнопку "Block Now"
/// - Статистику
///
/// РЕБЁНОК видит:
/// - Сколько времени использовано сегодня
/// - Какие ограничения активны
/// - Когда наступит bedtime
/// - НЕ видит кнопок управления ограничениями
public enum UserRole: String, Codable {
    case parent = "parent"
    case child = "child"
    
    /// Название роли для отображения в интерфейсе
    public var displayName: String {
        switch self {
        case .parent: return "Parent / Guardian"
        case .child: return "Child"
        }
    }
    
    /// Иконка роли (SF Symbols — встроенные иконки Apple)
    public var iconName: String {
        switch self {
        case .parent: return "person.badge.shield.checkmark"
        case .child: return "face.smiling"
        }
    }
}
