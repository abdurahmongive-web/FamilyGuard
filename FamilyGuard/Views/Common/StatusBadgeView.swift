// StatusBadgeView.swift
// FamilyGuard
//
// ЗАЧЕМ ЭТОТ ФАЙЛ:
// Универсальный бейдж-индикатор статуса (Активен, Заблокирован, Защищён).

import SwiftUI

public enum BadgeStatus {
    case active
    case blocked
    case secure
    case idle
}

public struct StatusBadgeView: View {
    public let status: BadgeStatus
    public let label: String
    
    public init(status: BadgeStatus, label: String) {
        self.status = status
        self.label = label
    }
    
    private var badgeColor: Color {
        switch status {
        case .active: return .blue
        case .blocked: return .red
        case .secure: return .green
        case .idle: return .secondary
        }
    }
    
    public var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(badgeColor)
                .frame(width: 8, height: 8)
            
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(badgeColor)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(badgeColor.opacity(0.12))
        .cornerRadius(12)
    }
}
