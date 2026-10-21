// ParentChoreCreatorSheet.swift
// FamilyGuard
//
// ЗАЧЕМ ЭТОТ ФАЙЛ:
// Модальное окно, где опекун пишет условие и сам указывает время награды.

import SwiftUI

public struct ParentChoreCreatorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var rewardService = ChoreRewardService.shared
    
    @State private var taskTitle: String = ""
    @State private var selectedMinutes: Int = 30
    @State private var customMinutesText: String = ""
    @State private var isCustomMinutes: Bool = false
    
    let minutePresets = [15, 30, 45, 60, 90]
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Условие задания")) {
                    TextField("Например: Выучить стихотворение, помыть посуду...", text: $taskTitle)
                        .font(.body)
                }
                
                Section(header: Text("Награда (сколько минут добавить)")) {
                    // Быстрый выбор популярных интервалов
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(minutePresets, id: \.self) { mins in
                                Button(action: {
                                    selectedMinutes = mins
                                    isCustomMinutes = false
                                }) {
                                    Text("+\(mins) мин")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(selectedMinutes == mins && !isCustomMinutes ? .white : .primary)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(selectedMinutes == mins && !isCustomMinutes ? Color.green : Color(uiColor: .tertiarySystemFill))
                                        .cornerRadius(10)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    
                    // Поле для произвольного ввода любого числа минут
                    Toggle("Ввести своё время вручную", isOn: $isCustomMinutes)
                    
                    if isCustomMinutes {
                        HStack {
                            TextField("Количество минут", text: $customMinutesText)
                                .keyboardType(.numberPad)
                            Text("минут")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Новое задание")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Создать") {
                        let finalMinutes = isCustomMinutes ? (Int(customMinutesText) ?? 30) : selectedMinutes
                        if !taskTitle.isEmpty {
                            rewardService.createChore(title: taskTitle, rewardMinutes: finalMinutes)
                            dismiss()
                        }
                    }
                    .fontWeight(.bold)
                    .disabled(taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
