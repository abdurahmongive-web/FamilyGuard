// ParentRewardsDashboardView.swift
// FamilyGuard
//
// ЗАЧЕМ ЭТОТ ФАЙЛ:
// Экран опекуна для управления заданиями и подтверждения наград ребёнку.

import SwiftUI

public struct ParentRewardsDashboardView: View {
    @ObservedObject private var rewardService = ChoreRewardService.shared
    @State private var showCreateSheet = false
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                // Кнопка создания нового кастомного задания
                Button(action: { showCreateSheet = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                        Text("Создать своё задание")
                            .font(.headline)
                        Spacer()
                    }
                    .padding(16)
                    .background(Color.blue.opacity(0.12))
                    .foregroundColor(.blue)
                    .cornerRadius(16)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                // Список заданий
                VStack(alignment: .leading, spacing: 14) {
                    Text("Активные задания и награды")
                        .font(.headline)
                        .padding(.horizontal, 16)
                    
                    ForEach(rewardService.chores) { chore in
                        ChoreRowView(chore: chore, onApprove: {
                            rewardService.approveChore(choreId: chore.id)
                        }, onDelete: {
                            rewardService.deleteChore(choreId: chore.id)
                        })
                    }
                }
            }
        }
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Задания и Награды")
        .sheet(isPresented: $showCreateSheet) {
            ParentChoreCreatorSheet()
        }
    }
}

private struct ChoreRowView: View {
    let chore: ChoreTask
    let onApprove: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(chore.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Награда: +\(chore.rewardMinutes) минут экранного времени")
                        .font(.caption)
                        .foregroundColor(.green)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Статус и кнопка одобрения
            HStack {
                switch chore.status {
                case .pending:
                    Text("Ждёт выполнения ребёнком")
                        .font(.caption)
                        .foregroundColor(.secondary)
                case .waitingApproval:
                    HStack {
                        Text("Ребёнок выполнил! 🎉")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                        
                        Spacer()
                        
                        Button(action: onApprove) {
                            Text("Одобрить и наградить")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Color.green)
                                .cornerRadius(10)
                        }
                    }
                case .approved:
                    Text("Выполнено и начислено ✅")
                        .font(.caption)
                        .foregroundColor(.green)
                case .rejected:
                    Text("Отклонено")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(16)
        .padding(.horizontal, 16)
    }
}
