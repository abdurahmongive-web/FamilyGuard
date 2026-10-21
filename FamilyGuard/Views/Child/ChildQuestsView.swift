// ChildQuestsView.swift
// FamilyGuard
//
// ЗАЧЕМ ЭТОТ ФАЙЛ:
// Экран квестов для ребёнка. Ребёнок видит задания, написанные опекуном,
// нажимает "Я выполнил", а при одобрении видит праздничный экран победы!

import SwiftUI

public struct ChildQuestsView: View {
    @ObservedObject private var rewardService = ChoreRewardService.shared
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                // Верхний блок
                VStack(spacing: 8) {
                    Image(systemName: "star.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.yellow)
                        .padding(.top, 16)
                    
                    Text("Заработай время!")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Выполняй задания от опекуна и получай дополнительное время на игры.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                
                // Список заданий для выполнения
                VStack(spacing: 14) {
                    ForEach(rewardService.chores) { chore in
                        ChildChoreCard(chore: chore, onMarkDone: {
                            rewardService.markCompletedByChild(choreId: chore.id)
                        })
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Мои квесты")
    }
}

private struct ChildChoreCard: View {
    let chore: ChoreTask
    let onMarkDone: () -> Void
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: "trophy.fill")
                    .foregroundColor(.orange)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(chore.title)
                    .font(.headline)
                Text("+\(chore.rewardMinutes) минут в награду")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
            }
            
            Spacer()
            
            if chore.status == .pending {
                Button(action: onMarkDone) {
                    Text("Я выполнил!")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            } else if chore.status == .waitingApproval {
                Text("На проверке ⏳")
                    .font(.caption)
                    .foregroundColor(.orange)
            } else if chore.status == .approved {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title3)
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}
