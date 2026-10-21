// ChoreRewardService.swift
// FamilyGuard
//
// ЗАЧЕМ ЭТОТ ФАЙЛ:
// Управляет списком полезных дел и начислением бонусного времени.
// Опекун создаёт произвольные задания с любым количеством минут,
// ребёнок отмечает выполнение, а опекун подтверждает начисление времени.

import Foundation
import Combine

public final class ChoreRewardService: ObservableObject {
    
    public static let shared = ChoreRewardService()
    
    private let storageKey = "familyguard.choresList"
    
    @Published public var chores: [ChoreTask] = []
    
    private init() {
        loadChores()
        if chores.isEmpty {
            seedDefaultChores()
        }
    }
    
    // MARK: - CRUD
    
    /// Опекун создаёт кастомное задание со своим условием и своим временем
    public func createChore(title: String, rewardMinutes: Int, childName: String = "Ребёнок") {
        let newChore = ChoreTask(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            rewardMinutes: max(rewardMinutes, 5),
            assignedChildName: childName
        )
        chores.insert(newChore, at: 0)
        saveChores()
        print("📝 [ChoreRewardService] Создано задание: '\(title)' на +\(rewardMinutes) мин")
    }
    
    /// Ребёнок отмечает, что выполнил задание
    public func markCompletedByChild(choreId: UUID) {
        if let index = chores.firstIndex(where: { $0.id == choreId }) {
            chores[index].status = .waitingApproval
            saveChores()
            print("🙋 [ChoreRewardService] Ребёнок отметил выполнение: \(chores[index].title)")
        }
    }
    
    /// Опекун одобряет задание: время автоматически начисляется ребёнку!
    @MainActor
    public func approveChore(choreId: UUID) {
        if let index = chores.firstIndex(where: { $0.id == choreId }) {
            let chore = chores[index]
            chores[index].status = .approved
            chores[index].completedAt = Date()
            saveChores()
            
            // Начисляем заработанное время через наш ManagedSettingsService!
            ManagedSettingsService.shared.grantBonusTime(minutes: chore.rewardMinutes)
            print("🏆 [ChoreRewardService] Задание одобрено! Начислено +\(chore.rewardMinutes) минут ребёнку")
        }
    }
    
    public func deleteChore(choreId: UUID) {
        chores.removeAll { $0.id == choreId }
        saveChores()
    }
    
    // MARK: - Storage
    
    private func saveChores() {
        if let data = try? JSONEncoder().encode(chores) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    private func loadChores() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let loaded = try? JSONDecoder().decode([ChoreTask].self, from: data) else {
            return
        }
        self.chores = loaded
    }
    
    private func seedDefaultChores() {
        chores = [
            ChoreTask(title: "Сделать домашнее задание", rewardMinutes: 45),
            ChoreTask(title: "Убрать в своей комнате", rewardMinutes: 30),
            ChoreTask(title: "Почитать книгу 30 минут", rewardMinutes: 30)
        ]
        saveChores()
    }
}
