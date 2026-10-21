// AppState.swift
// FamilyGuard
//
// ЗАЧЕМ ЭТОТ ФАЙЛ:
// Глобальное состояние приложения. Решает, какой экран показать пользователю:
//
// 1. Первый запуск? → Onboarding (Welcome → Пошаговая инструкция → Выбор роли)
// 2. Onboarding пройден, роль = Parent? → Parent Dashboard
// 3. Onboarding пройден, роль = Child? → Child Dashboard

import Foundation
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    
    // MARK: - Navigation State
    
    enum NavigationState {
        /// Первый запуск — приветственный экран
        case onboarding
        /// Инструкция по настройке перед выбором роли
        case setupGuide
        /// Выбор роли — Parent или Child
        case roleSelection
        /// Авторизация родителя в Apple Screen Time
        case parentAuthorization
        /// Основной экран родителя
        case parentDashboard
        /// Основной экран ребёнка
        case childDashboard
    }
    
    @Published var currentState: NavigationState = .onboarding
    @Published var userRole: UserRole?
    
    init() {
        loadSavedState()
    }
    
    // MARK: - Navigation Methods
    
    /// Переход к инструкции по настройке
    func proceedToSetupGuide() {
        currentState = .setupGuide
    }
    
    /// Переход к выбору роли (после инструкции)
    func proceedToRoleSelection() {
        currentState = .roleSelection
    }
    
    /// Выбор роли и переход к соответствующему экрану
    func selectRole(_ role: UserRole) {
        userRole = role
        AppGroupStorage.shared.saveUserRole(role.rawValue)
        
        switch role {
        case .parent:
            currentState = .parentAuthorization
        case .child:
            currentState = .childDashboard
        }
    }
    
    /// Переход к Parent Dashboard после успешной авторизации
    func proceedToParentDashboard() {
        AppGroupStorage.shared.setOnboardingCompleted()
        currentState = .parentDashboard
    }
    
    /// Переход к Child Dashboard
    func proceedToChildDashboard() {
        AppGroupStorage.shared.setOnboardingCompleted()
        currentState = .childDashboard
    }
    
    /// Сброс состояния
    func reset() {
        userRole = nil
        currentState = .onboarding
    }
    
    // MARK: - Persistence
    
    private func loadSavedState() {
        if AppGroupStorage.shared.hasCompletedOnboarding() {
            if let roleString = AppGroupStorage.shared.loadUserRole(),
               let role = UserRole(rawValue: roleString) {
                self.userRole = role
                switch role {
                case .parent:
                    currentState = .parentDashboard
                case .child:
                    currentState = .childDashboard
                }
            } else {
                currentState = .onboarding
            }
        } else {
            currentState = .onboarding
        }
    }
}
