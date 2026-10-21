// QuickPasscodeModalView.swift
// FamilyGuard
//
// ЗАЧЕМ ЭТОТ ФАЙЛ:
// Быстрый ввод родительского 4-значного кода прямо на детском устройстве.
// Включает ЗАЩИТУ ОТ ПОДБОРА (Anti-Brute Force): после 3 неверных попыток
// блокирует ввод на 60 секунд.

import SwiftUI

public struct QuickPasscodeModalView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var enteredCode: String = ""
    @State private var isCodeValid = false
    @State private var errorMessage: String?
    @State private var failedAttempts: Int = 0
    @State private var lockoutSecondsRemaining: Int = 0
    @State private var isLockedOut: Bool = false
    
    private let correctCode = "1234"
    private let maxAttempts = 3
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                
                ZStack {
                    Circle()
                        .fill((isLockedOut ? Color.red : Color.blue).opacity(0.12))
                        .frame(width: 72, height: 72)
                    Image(systemName: isLockedOut ? "lock.shield.fill" : "key.horizontal.fill")
                        .font(.title)
                        .foregroundColor(isLockedOut ? .red : .blue)
                }
                .padding(.top, 24)
                
                VStack(spacing: 6) {
                    Text(isLockedOut ? "Ввод временно заблокирован" : "Родительский доступ")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(isLockedOut ? "Слишком много неверных попыток. Подождите окончания таймера." : "Введите 4-значный код опекуна для быстрого управления на этом устройстве")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                
                if isLockedOut {
                    // Таймер блокировки от подбора
                    VStack(spacing: 8) {
                        Text("\(lockoutSecondsRemaining) сек.")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.red)
                        Text("Защита от подбора активна")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else if !isCodeValid {
                    // Поле ввода 4 цифр
                    SecureField("••••", text: $enteredCode)
                        .keyboardType(.numberPad)
                        .font(.system(size: 32, weight: .bold))
                        .multilineTextAlignment(.center)
                        .frame(width: 160, height: 50)
                        .background(Color(uiColor: .secondarySystemBackground))
                        .cornerRadius(12)
                        .onChange(of: enteredCode) { newValue in
                            if newValue.count == 4 {
                                if newValue == correctCode {
                                    isCodeValid = true
                                    errorMessage = nil
                                    failedAttempts = 0
                                } else {
                                    failedAttempts += 1
                                    enteredCode = ""
                                    if failedAttempts >= maxAttempts {
                                        startLockout()
                                    } else {
                                        errorMessage = "Неверный код (попытка \(failedAttempts) из \(maxAttempts))"
                                    }
                                }
                            }
                        }
                    
                    if let err = errorMessage {
                        Text(err)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                } else {
                    // Варианты добавления времени
                    VStack(spacing: 12) {
                        Text("Выберите действие:")
                            .font(.headline)
                        
                        Button("+15 минут") {
                            ManagedSettingsService.shared.grantBonusTime(minutes: 15)
                            dismiss()
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.blue.opacity(0.12))
                        .foregroundColor(.blue)
                        .cornerRadius(12)
                        
                        Button("+30 минут") {
                            ManagedSettingsService.shared.grantBonusTime(minutes: 30)
                            dismiss()
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.blue.opacity(0.12))
                        .foregroundColor(.blue)
                        .cornerRadius(12)
                        
                        Button("+1 час") {
                            ManagedSettingsService.shared.grantBonusTime(minutes: 60)
                            dismiss()
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.blue.opacity(0.12))
                        .foregroundColor(.blue)
                        .cornerRadius(12)
                        
                        Button("Снять ограничения на сегодня") {
                            ManagedSettingsService.shared.removeDailyLimitForToday()
                            dismiss()
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 24)
                }
                
                Spacer()
            }
            .navigationTitle("Код Опекуна")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
            }
        }
    }
    
    private func startLockout() {
        isLockedOut = true
        lockoutSecondsRemaining = 60
        errorMessage = nil
        
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
