// OptionalFeaturesSettingsView.swift
// FamilyGuard
//
// ЗАЧЕМ ЭТОТ ФАЙЛ:
// Экран настроек, где опекун может опционально включить или выключить:
// 1. Режим фокуса на учёбе
// 3. Быстрый 4-значный код на телефоне ребёнка
// 4. Серию хороших привычек (Streak)

import SwiftUI

public struct OptionalFeaturesSettingsView: View {
    @AppStorage("familyguard.studyFocusEnabled") private var isStudyFocusEnabled = false
    @AppStorage("familyguard.quickPasscodeEnabled") private var isQuickPasscodeEnabled = true
    @AppStorage("familyguard.habitStreakEnabled") private var isHabitStreakEnabled = true
    
    public init() {}
    
    public var body: some View {
        Form {
            // Опция 1: Режим учёбы
            Section(header: Text("Опция 1: Учёба и фокус"), footer: Text("Блокирует только игры и соцсети, оставляя доступ к электронному дневнику, учебникам и калькулятору.")) {
                Toggle("Режим фокуса на учёбе", isOn: $isStudyFocusEnabled)
            }
            
            // Опция 3: Быстрый код на телефоне ребёнка
            Section(header: Text("Опция 3: Быстрый доступ"), footer: Text("Позволяет опекуну ввести 4-значный код прямо на детском телефоне для быстрой выдачи времени.")) {
                Toggle("Быстрый родительский код", isOn: $isQuickPasscodeEnabled)
            }
            
            // Опция 4: Геймификация привычек
            Section(header: Text("Опция 4: Серия привычек (Streak)"), footer: Text("Считает дни без нарушений, мотивирует ребёнка и открывает бейджи за дисциплину.")) {
                Toggle("Счётчик хороших привычек", isOn: $isHabitStreakEnabled)
            }
            
            // Фича 2: Белый список (всегда активен)
            Section(header: Text("Безопасность (Всегда активно)")) {
                HStack {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundColor(.green)
                    VStack(alignment: .leading) {
                        Text("Белый список первой необходимости")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("Звонки родителям, SOS и карты никогда не блокируются")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Дополнительные опции")
        .navigationBarTitleDisplayMode(.inline)
    }
}
