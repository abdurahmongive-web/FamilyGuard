// EmergencyRecoveryService.swift
// FamilyGuard
//
// ЗАЧЕМ ЭТОТ ФАЙЛ:
// Управляет экстренным доступом и восстановлением при потере телефона опекуна или ребёнка.
//
// ЧТО ДЕЛАЕТ ПРИ ПОТЕРЕ ТЕЛЕФОНА ОПЕКУНА:
// 1. Позволяет прямо на заблокированном телефоне ребёнка ввести Мастер-PIN
//    и мгновенно снять все блокировки ManagedSettingsStore.
// 2. Позволяет на новом телефоне опекуна ввести Recovery Key и восстановить управление.

import Foundation
import CryptoKit

public final class EmergencyRecoveryService {
    
    public static let shared = EmergencyRecoveryService()
    
    private let storageKey = "familyguard.emergencyRecoveryConfig"
    
    private init() {}
    
    // MARK: - Setup Recovery
    
    /// Создаёт новую конфигурацию экстренного восстановления
    public func setupRecovery(pin: String, email: String) -> String {
        let pinHash = hashPin(pin)
        let key = generateRecoveryKey()
        let config = EmergencyRecoveryConfig(
            masterPinHash: pinHash,
            backupContactEmail: email,
            emergencyRecoveryKey: key
        )
        
        saveConfig(config)
        print("🛡️ [EmergencyRecoveryService] Экстренный аккаунт настроен. Ключ: \(key)")
        return key
    }
    
    // MARK: - Verification
    
    /// Проверяет введённый Мастер-PIN
    public func verifyPin(_ pin: String) -> Bool {
        guard let config = loadConfig() else { return false }
        let enteredHash = hashPin(pin)
        return enteredHash == config.masterPinHash
    }
    
    /// Проверяет введённый Аварийный ключ (Recovery Key)
    public func verifyRecoveryKey(_ key: String) -> Bool {
        guard let config = loadConfig() else { return false }
        let cleanKey = key.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        return cleanKey == config.emergencyRecoveryKey
    }
    
    /// Экстренная разблокировка: снимает все ограничения на устройстве
    @MainActor
    public func performEmergencyUnlock() -> Bool {
        ManagedSettingsService.shared.removeAllRestrictions()
        print("🚨 [EmergencyRecoveryService] Выполнена ЭКСТРЕННАЯ РАЗБЛОКИРОВКА устройства!")
        return true
    }
    
    // MARK: - Helpers
    
    private func hashPin(_ pin: String) -> String {
        let inputData = Data(pin.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    private func generateRecoveryKey() -> String {
        let parts = (0..<4).map { _ in String(format: "%04d", Int.random(in: 1000...9999)) }
        return "FG-" + parts.joined(separator: "-")
    }
    
    private func saveConfig(_ config: EmergencyRecoveryConfig) {
        if let data = try? JSONEncoder().encode(config) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    public func loadConfig() -> EmergencyRecoveryConfig? {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return nil }
        return try? JSONDecoder().decode(EmergencyRecoveryConfig.self, from: data)
    }
    
    public var isRecoveryConfigured: Bool {
        loadConfig() != nil
    }
}
