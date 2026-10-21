// ParentAuthorizationView.swift
// FamilyGuard
//
// ЗАЧЕМ ЭТОТ ФАЙЛ:
// Запрашивает системное разрешение Apple Screen Time API у опекуна.

import SwiftUI
import FamilyControls

public struct ParentAuthorizationView: View {
    @EnvironmentObject private var familyControlsService: FamilyControlsService
    public let onAuthorized: () -> Void
    
    @State private var isAuthorizing = false
    
    public init(onAuthorized: @escaping () -> Void) {
        self.onAuthorized = onAuthorized
    }
    
    public var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "lock.shield.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.blue)
            
            VStack(spacing: 12) {
                Text("Разрешение Screen Time")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("FamilyGuard использует официальные API Apple для безопасного управления приложениями без нарушения приватности.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
            
            VStack(spacing: 12) {
                // Кнопка для реального режима ребёнка (Family Sharing)
                Button(action: {
                    Task {
                        isAuthorizing = true
                        await familyControlsService.requestChildAuthorization()
                        isAuthorizing = false
                        if familyControlsService.isAuthorized {
                            onAuthorized()
                        }
                    }
                }) {
                    HStack {
                        if isAuthorizing {
                            ProgressView()
                                .tint(.white)
                                .padding(.trailing, 8)
                        }
                        Text("Авторизовать для ребёнка")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(14)
                }
                
                // Кнопка для индивидуального режима (тесты на одном устройстве)
                Button(action: {
                    Task {
                        isAuthorizing = true
                        await familyControlsService.requestIndividualAuthorization()
                        isAuthorizing = false
                        if familyControlsService.isAuthorized {
                            onAuthorized()
                        }
                    }
                }) {
                    Text("Индивидуальный режим (для тестов)")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .padding(.vertical, 8)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .alert(isPresented: $familyControlsService.showError) {
            Alert(
                title: Text("Ошибка авторизации"),
                message: Text(familyControlsService.errorMessage ?? "Неизвестная ошибка"),
                dismissButton: .default(Text("Понятно"))
            )
        }
    }
}
