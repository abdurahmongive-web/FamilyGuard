// EmergencyRecovery.swift
// FamilyGuard
//
// ЗАЧЕМ ЭТОТ ФАЙЛ:
// Модель данных для системы экстренного восстановления при потере устройства.
// Содержит Мастер-PIN (6 цифр), резервный email/телефон и аварийный ключ разблокировки.

import Foundation

public struct EmergencyRecoveryConfig: Codable {
    /// 6-значный мастер-пин код для экстренной разблокировки на месте
    public var masterPinHash: String
    
    /// Резервный контакт (email опекуна или резервный Apple ID)
    public var backupContactEmail: String
    
    /// Сгенерированный аварийный ключ (например "FG-9281-4412-8823-1104")
    public var emergencyRecoveryKey: String
    
    /// Дата создания конфигурации
    public var createdAt: Date
    
    public init(masterPinHash: String, backupContactEmail: String, emergencyRecoveryKey: String) {
        self.masterPinHash = masterPinHash
        self.backupContactEmail = backupContactEmail
        self.emergencyRecoveryKey = emergencyRecoveryKey
        self.createdAt = Date()
    }
}
