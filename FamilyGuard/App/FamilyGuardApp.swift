// FamilyGuardApp.swift
// FamilyGuard
//
// ЗАЧЕМ ЭТОТ ФАЙЛ:
// Главная точка входа (@main) iOS-приложения FamilyGuard.
// Инициализирует глобальные сервисы и роутер навигации AppState.

import SwiftUI
import FamilyControls

@main
struct FamilyGuardApp: App {
    
    @StateObject private var appState = AppState()
    @StateObject private var familyControlsService = FamilyControlsService.shared
    @StateObject private var managedSettingsService = ManagedSettingsService.shared
    
    var body: some Scene {
        WindowGroup {
            Group {
                switch appState.currentState {
                case .onboarding:
                    WelcomeView(onContinue: {
                        appState.proceedToSetupGuide()
                    })
                    
                case .setupGuide:
                    SetupGuideView(onContinue: {
                        appState.proceedToRoleSelection()
                    })
                    
                case .roleSelection:
                    RoleSelectionView(onSelectRole: { role in
                        appState.selectRole(role)
                    })
                    
                case .parentAuthorization:
                    ParentAuthorizationView(onAuthorized: {
                        appState.proceedToParentDashboard()
                    })
                    
                case .parentDashboard:
                    ParentDashboardView()
                    
                case .childDashboard:
                    ChildDashboardView()
                }
            }
            .environmentObject(appState)
            .environmentObject(familyControlsService)
            .environmentObject(managedSettingsService)
        }
    }
}
