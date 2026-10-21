// AppPickerView.swift
// FamilyGuard
//
// ЗАЧЕМ ЭТОТ ФАЙЛ:
// Обертка для нативного системного компонента Apple FamilyActivityPicker.
// Позволяет родителю безопасно выбирать приложения, категории и веб-домены
// для применения ограничений.

import SwiftUI
import FamilyControls

public struct AppPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var familyControlsService: FamilyControlsService
    
    @State private var pickerSelection = FamilyActivitySelection()
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                
                // Верхний информационный блок
                VStack(spacing: 8) {
                    Text("Выберите приложения и игры")
                        .font(.headline)
                    
                    Text("Apple гарантирует конфиденциальность: токены зашифрованы и не передаются на сторонние серверы.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
                .padding(.vertical, 16)
                
                // Встроенный системный пикер Apple
                FamilyActivityPicker(selection: $pickerSelection)
                    .frame(maxHeight: .infinity)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Выбор приложений")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        familyControlsService.updateSelection(pickerSelection)
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
            .onAppear {
                self.pickerSelection = familyControlsService.activitySelection
            }
        }
    }
}
