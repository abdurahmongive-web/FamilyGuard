// ChoreTask.swift
// FamilyGuard
//
// ЗАЧЕМ ЭТОТ ФАЙЛ:
// Модель полезного задания (квеста), которое опекун создаёт для ребёнка.
// Опекун сам пишет условие (текст) и указывает награду (любое количество минут).

import Foundation

public enum ChoreStatus: String, Codable {
    /// Задание активно и ждёт выполнения ребёнком
    case pending = "pending"
    /// Ребёнок нажал "Я выполнил", ждёт проверки и одобрения опекуна
    case waitingApproval = "waitingApproval"
    /// Опекун одобрил задание, награда зачислена на баланс
    case approved = "approved"
    /// Отклонено опекуном
    case rejected = "rejected"
}

public struct ChoreTask: Identifiable, Codable {
    public let id: UUID
    /// Условие задания, написанное опекуном (например "Убрать в комнате", "Сделать математику")
    public var title: String
    /// Количество бонусных минут, которые назначил опекун (например 15, 30, 45, 60 мин)
    public var rewardMinutes: Int
    /// Имя ребёнка, для которого создано задание
    public var assignedChildName: String
    /// Текущий статус выполнения
    public var status: ChoreStatus
    /// Дата создания
    public var createdAt: Date
    /// Дата выполнения
    public var completedAt: Date?
    
    public init(
        id: UUID = UUID(),
        title: String,
        rewardMinutes: Int,
        assignedChildName: String = "Ребёнок",
        status: ChoreStatus = .pending,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.rewardMinutes = rewardMinutes
        self.assignedChildName = assignedChildName
        self.status = status
        self.createdAt = createdAt
    }
    
    public var formattedReward: String {
        return "+\(rewardMinutes) мин"
    }
}
