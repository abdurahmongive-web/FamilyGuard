// EmergencyRecoveryView.swift
// FamilyGuard
//
// ЗАЧЕМ ЭТОТ ФАЙЛ:
// Экран экстренной разблокировки при утере телефона опекуна.
// Опекун вводит 6-значный Мастер-PIN.
// Включает ЗАЩИТУ ОТ ПОДБОРА (Anti-Brute Force): после 3 неверных попыток
// блокирует ввод на 120 секунд.

import SwiftUI

public struct EmergencyRecoveryView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var pin: String = ""
    @State private var errorMessage: String?
    @State private var isSuccess = false
    @State private var failedAttempts: Int = 0
    @State private var lockoutSecondsRemaining: Int = 0
    @State private var isLockedOut: Bool = false
    
    private let maxAttempts = 3
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.12))
                        .frame(width: 80, height: 80)
                    Image(systemName: "exclamationmark.shield.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 44, height: 44)
                        .foregroundColor(.red)
                }
                .padding(.top, 24)
                
                VStack(spacing: 8) {
                    Text(isLockedOut ? "Ввод временно заблокирован" : "Экстренное восстановление")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(isLockedOut ? "Слишком много неверных попыток ввода Мастер-PIN. Подождите окончания таймера." : "Используется при потере телефона опекуна. Введите 6-значный Мастер-PIN для немедленного снятия ограничений.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                
                if isLockedOut {
                    VStack(spacing: 8) {
                        Text("\(lockoutSecondsRemaining) сек.")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.red)
                        Text("Защита от несанкционированного доступа")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else {
                    VStack(spacing: 12) {
                        SecureField("Введите 6-значный PIN", text: $pin)
                            .keyboardType(.numberPad)
                            .font(.title2)
                            .multilineTextAlignment(.center)
                            .frame(height: 54)
                            .background(Color(uiColor: .secondarySystemBackground))
                            .cornerRadius(14)
                            .padding(.horizontal, 40)
                        
                        if let error = errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        if EmergencyRecoveryService.shared.verifyPin(pin) {
                            _ = EmergencyRecoveryService.shared.performEmergencyUnlock()
                            isSuccess = true
                            failedAttempts = 0
                        } else {
                            failedAttempts += 1
                            if failedAttempts >= maxAttempts {
                                startLockout()
                            } else {
                                errorMessage = "Неверный Мастер-PIN (попытка \(failedAttempts) из \(maxAttempts))"
                            }
                        }
                    }) {
                        Text("Разблокировать устройство")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.red)
                            .cornerRadius(14)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Аварийный доступ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { dismiss() }
                }
            }
            .alert("Устройство разблокировано", isPresented: $isSuccess) {
                Button("ОК") { dismiss() }
            } message: {
                Text("Все блокировки FamilyGuard успешно сняты.")
            }
        }
    }
    
    private func startLockout() {
        isLockedOut = true
        lockoutSecondsRemaining = 120
        errorMessage = nil
        pin = ""
        
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if lockoutSecondsRemaining > 1 {
                lockoutSecondsRemaining -= 1
            } else {
                timer.invalidate()
                isLockedOut = false
                failedAttempts = 0
            }
        }
    }
}
