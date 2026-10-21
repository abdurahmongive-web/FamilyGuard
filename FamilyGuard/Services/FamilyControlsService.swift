// FamilyControlsService.swift
// FamilyGuard
//
// ЗАЧЕМ ЭТОТ ФАЙЛ:
// Отвечает за системную авторизацию Apple Screen Time API.
// Без авторизации невозможно вызвать FamilyActivityPicker и наложить блокировку.

import Foundation
import FamilyControls
import Combine

@MainActor
public final class FamilyControlsService: ObservableObject {
    
    public static let shared = FamilyControlsService()
    
    @Published public var authorizationStatus: AuthorizationStatus = .notDetermined
    @Published public var activitySelection = FamilyActivitySelection()
    @Published public var errorMessage: String?
    @Published public var showError: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        AuthorizationCenter.shared.$authorizationStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newStatus in
                self?.authorizationStatus = newStatus
                print("📱 [FamilyControlsService] Статус авторизации: \(newStatus)")
            }
            .store(in: &cancellables)
        
        self.authorizationStatus = AuthorizationCenter.shared.authorizationStatus
        
        if let savedSelection = AppGroupStorage.shared.loadSelection() {
            self.activitySelection = savedSelection
        }
    }
    
    /// Авторизация для режима тестирования на одном устройстве
    public func requestIndividualAuthorization() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            self.authorizationStatus = AuthorizationCenter.shared.authorizationStatus
            self.errorMessage = nil
            self.showError = false
        } catch {
            handleAuthorizationError(error)
        }
    }
    
    /// Авторизация для устройства ребёнка в Apple Family Sharing
    public func requestChildAuthorization() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .child)
            self.authorizationStatus = AuthorizationCenter.shared.authorizationStatus
            self.errorMessage = nil
            self.showError = false
        } catch {
            handleAuthorizationError(error)
        }
    }
    
    public func revokeAuthorization() async {
        do {
            await withCheckedContinuation { continuation in
                AuthorizationCenter.shared.revokeAuthorization { _ in
                    continuation.resume()
                }
            }
            self.authorizationStatus = .notDetermined
            activitySelection = FamilyActivitySelection()
            AppGroupStorage.shared.clearSelection()
        } catch {
            errorMessage = "Failed to revoke: \(error.localizedDescription)"
            showError = true
        }
    }
    
    public func updateSelection(_ selection: FamilyActivitySelection) {
        self.activitySelection = selection
        AppGroupStorage.shared.saveSelection(selection)
    }
    
    public var isAuthorized: Bool {
        authorizationStatus == .approved
    }
    
    public var hasSelection: Bool {
        !activitySelection.applicationTokens.isEmpty ||
        !activitySelection.categoryTokens.isEmpty ||
        !activitySelection.webDomainTokens.isEmpty
    }
    
    private func handleAuthorizationError(_ error: Error) {
        if let fcError = error as? FamilyControlsError {
            switch fcError {
            case .restricted:
                errorMessage = "Screen Time is restricted on this device."
            case .unavailable:
                errorMessage = "Screen Time features are not available on this device."
            case .invalidAccountType:
                errorMessage = "This Apple Account type does not support Family Controls."
            case .authorizationConflict:
                errorMessage = "Another app is already managing Screen Time on this device."
            case .authorizationCanceled:
                errorMessage = "Authorization was canceled."
            case .networkError:
                errorMessage = "Network error. Please check your internet connection."
            @unknown default:
                errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
            }
        } else {
            errorMessage = "Authorization failed: \(error.localizedDescription)"
        }
        showError = true
    }
}
