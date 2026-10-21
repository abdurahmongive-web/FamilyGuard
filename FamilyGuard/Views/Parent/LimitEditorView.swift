// LimitEditorView.swift
// FamilyGuard
//
// ЗАЧЕМ ЭТОТ ФАЙЛ:
// Экран создания или редактирования дневного лимита.
//
// На этом экране родитель:
// 1. Вводит НАЗВАНИЕ лимита (например: "Social Media", "Games")
// 2. Выбирает ВРЕМЯ лимита (часы + минуты)
// 3. Выбирает ПРИЛОЖЕНИЯ через FamilyActivityPicker
// 4. Нажимает "Save" — лимит сохраняется и мониторинг запускается
//
// СХЕМА ЭКРАНА:
//
//   ┌──────────────────────────────────────┐
//   │  📝 New Limit                [Save]  │  ← NavigationBar
//   ├──────────────────────────────────────┤
//   │                                      │
//   │  Name: [__Social Media__________]    │  ← TextField
//   │                                      │
//   │  Duration:                            │
//   │  ┌────────┐   ┌────────┐             │
//   │  │  1 hr  ▼│   │ 30 min▼│             │  ← Picker (hours + minutes)
//   │  └────────┘   └────────┘             │
//   │                                      │
//   │  Apps & Categories:                   │
//   │  [Select Apps & Categories]           │  ← Кнопка FamilyActivityPicker
//   │                                      │
//   │  📱 YouTube                           │  ← Label(token)
//   │  📱 TikTok                            │
//   │  📂 Social Networking                 │
//   │                                      │
//   └──────────────────────────────────────┘
//
// ВАЛИДАЦИЯ:
// - Название не должно быть пустым
// - Время должно быть > 0 минут
// - Должен быть выбран хотя бы один элемент (приложение/категория/домен)
//
// ПОСЛЕ СОХРАНЕНИЯ:
// 1. Создаётся объект AppLimit
// 2. Вызывается onSave callback → LimitListView добавляет лимит в массив
// 3. AppGroupStorage сохраняет массив → расширения получают доступ
// 4. DeviceActivityService запускает мониторинг → Apple следит за использованием
// 5. Экран закрывается (dismiss)

import SwiftUI
import FamilyControls

/// Экран создания или редактирования дневного лимита использования.
///
/// Этот View содержит форму с полями ввода и кнопкой сохранения.
/// При сохранении создаёт объект AppLimit и запускает мониторинг.
///
/// Использование (создание нового лимита):
/// ```swift
/// LimitEditorView { newLimit in
///     limits.append(newLimit)
///     saveLimits()
/// }
/// .environmentObject(DeviceActivityService.shared)
/// .environmentObject(FamilyControlsService.shared)
/// ```
struct LimitEditorView: View {
    
    // MARK: - State Properties (Состояние формы)
    
    /// Название лимита, введённое пользователем.
    ///
    /// @State — локальное состояние View.
    /// TextField привязан к этой переменной через $name.
    /// Каждое нажатие клавиши обновляет значение.
    @State private var name: String = ""
    
    /// Количество часов лимита (0–12).
    ///
    /// Picker привязан к этой переменной.
    /// Максимум 12 часов — разумный предел для дневного лимита.
    /// Больше 12 часов = практически без ограничений.
    @State private var hours: Int = 1
    
    /// Количество минут лимита (0, 5, 10, 15, ..., 55).
    ///
    /// Шаг 5 минут — для удобства выбора.
    /// 1-минутная точность избыточна для родительского контроля.
    @State private var minutes: Int = 0
    
    /// Выбор приложений и категорий из FamilyActivityPicker.
    ///
    /// FamilyActivitySelection — структура Apple, содержащая:
    /// - applicationTokens: Set<ApplicationToken> — выбранные приложения
    /// - categoryTokens: Set<ActivityCategoryToken> — выбранные категории
    /// - webDomainTokens: Set<WebDomainToken> — выбранные веб-домены
    @State private var selection: FamilyActivitySelection = FamilyActivitySelection()
    
    /// Флаг показа FamilyActivityPicker.
    ///
    /// Когда true — iOS показывает системный экран выбора приложений.
    /// Когда пользователь закрывает пикер — автоматически становится false.
    @State private var pickerIsPresented: Bool = false
    
    /// Флаг показа предупреждения о невалидных данных.
    ///
    /// Показывается, когда пользователь нажимает "Save",
    /// но форма не прошла валидацию.
    @State private var showValidationAlert: Bool = false
    
    /// Текст ошибки валидации для отображения в alert.
    @State private var validationMessage: String = ""
    
    // MARK: - Environment & Dependencies (Зависимости)
    
    /// Функция закрытия текущего экрана.
    ///
    /// @Environment(\.dismiss) — доступ к системному действию "закрыть экран".
    /// Работает как для push navigation (NavigationLink), так и для modal (sheet).
    ///
    /// При вызове dismiss():
    /// - Если экран был открыт через NavigationLink → pop (возврат назад)
    /// - Если экран был открыт через .sheet() → dismiss (закрытие модального окна)
    @Environment(\.dismiss) private var dismiss
    
    /// Сервис управления мониторингом DeviceActivity.
    ///
    /// Используется для запуска мониторинга после создания лимита.
    /// Инжектируется через .environmentObject() в родительском View.
    @EnvironmentObject var deviceActivityService: DeviceActivityService
    
    /// Сервис управления FamilyControls.
    ///
    /// Используется для обновления глобального выбора приложений.
    /// Инжектируется через .environmentObject() в родительском View.
    @EnvironmentObject var familyControlsService: FamilyControlsService
    
    // MARK: - Callback (Обратный вызов)
    
    /// Замыкание (closure), вызываемое при успешном сохранении лимита.
    ///
    /// Родительский View (LimitListView) передаёт это замыкание,
    /// чтобы получить новый лимит и добавить его в свой массив.
    ///
    /// Пример использования из LimitListView:
    /// ```swift
    /// LimitEditorView { newLimit in
    ///     limits.append(newLimit)
    ///     saveLimits()
    /// }
    /// ```
    var onSave: (AppLimit) -> Void
    
    // MARK: - Computed Properties (Вычисляемые свойства)
    
    /// Общее время лимита в минутах.
    ///
    /// Пример: hours = 1, minutes = 30 → totalMinutes = 90
    /// Используется для создания AppLimit и валидации.
    private var totalMinutes: Int {
        hours * 60 + minutes
    }
    
    /// Проверяет, валидна ли форма для сохранения.
    ///
    /// Форма валидна, если:
    /// 1. Название не пустое (после удаления пробелов)
    /// 2. Время > 0 минут
    /// 3. Выбрано хотя бы одно приложение, категория или домен
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        totalMinutes > 0 &&
        hasSelection
    }
    
    /// Есть ли выбранные элементы в FamilyActivitySelection.
    ///
    /// Проверяет, что хотя бы один из трёх типов токенов не пуст.
    private var hasSelection: Bool {
        !selection.applicationTokens.isEmpty ||
        !selection.categoryTokens.isEmpty ||
        !selection.webDomainTokens.isEmpty
    }
    
    /// Общее количество выбранных элементов.
    private var totalSelectedCount: Int {
        selection.applicationTokens.count +
        selection.categoryTokens.count +
        selection.webDomainTokens.count
    }
    
    // MARK: - Body (Основной интерфейс)
    
    var body: some View {
        
        // Form — контейнер для формы ввода данных.
        // Это стилизованный List с группировкой в секции.
        // Стандартный компонент для экранов настроек в iOS.
        // Автоматически добавляет:
        // - Группировку в секции
        // - Разделители между полями
        // - Правильные отступы
        // - Поддержку клавиатуры
        Form {
            
            // ────────────────────────────────────────
            // СЕКЦИЯ 1: Название лимита
            // ────────────────────────────────────────
            nameSection
            
            // ────────────────────────────────────────
            // СЕКЦИЯ 2: Выбор времени (часы + минуты)
            // ────────────────────────────────────────
            durationSection
            
            // ────────────────────────────────────────
            // СЕКЦИЯ 3: Выбор приложений
            // ────────────────────────────────────────
            appsSelectionSection
            
            // ────────────────────────────────────────
            // СЕКЦИЯ 4: Список выбранных элементов
            // ────────────────────────────────────────
            if hasSelection {
                selectedItemsSection
            }
            
            // ────────────────────────────────────────
            // СЕКЦИЯ 5: Кнопка "Save"
            // ────────────────────────────────────────
            saveButtonSection
        }
        // Заголовок экрана.
        .navigationTitle("New Limit")
        // .navigationBarTitleDisplayMode(.inline) — маленький заголовок по центру.
        // .large = крупный, .inline = маленький.
        // Для вложенных экранов (не главных) рекомендуется .inline.
        .navigationBarTitleDisplayMode(.inline)
        // ────────────────────────────────────────
        // МОДИФИКАТОР: FamilyActivityPicker
        // ────────────────────────────────────────
        // Показывает системный пикер Apple при pickerIsPresented = true.
        // Результат выбора автоматически записывается в selection.
        .familyActivityPicker(
            isPresented: $pickerIsPresented,
            selection: $selection
        )
        // ────────────────────────────────────────
        // МОДИФИКАТОР: Alert для ошибок валидации
        // ────────────────────────────────────────
        // .alert — показывает системный алерт (диалоговое окно).
        // isPresented: $showValidationAlert — когда true, алерт показан.
        .alert("Cannot Save", isPresented: $showValidationAlert) {
            // Кнопка "OK" — закрывает алерт.
            // .default = стандартная кнопка (синий текст).
            Button("OK", role: .cancel) { }
        } message: {
            // Текст сообщения — объясняет, что нужно исправить.
            Text(validationMessage)
        }
    }
    
    // MARK: - Form Sections (Секции формы)
    
    /// Секция с полем ввода названия лимита.
    ///
    /// Section — группирующий контейнер в Form.
    /// header: — текст над секцией (маленькими серыми буквами).
    /// footer: — текст под секцией (пояснение).
    private var nameSection: some View {
        
        Section {
            // TextField — поле ввода текста.
            // Первый аргумент — placeholder (подсказка, пока поле пустое).
            // $name — двухсторонняя привязка к @State переменной.
            // Каждое нажатие клавиши обновляет name.
            TextField("e.g. Social Media, Games", text: $name)
                // .autocorrectionDisabled() — отключает автокоррекцию.
                // Для названий лимитов автокоррекция мешает.
                .autocorrectionDisabled()
        } header: {
            // Заголовок секции — маленький серый текст над полем.
            Text("Limit Name")
        } footer: {
            // Подпись секции — маленький серый текст под полем.
            // Помогает пользователю понять, что вводить.
            Text("Give this limit a descriptive name so you can identify it later.")
        }
    }
    
    /// Секция с выбором длительности лимита (часы + минуты).
    ///
    /// Использует два Picker (колёсика выбора):
    /// - Hours: 0, 1, 2, ..., 12
    /// - Minutes: 0, 5, 10, 15, ..., 55
    ///
    /// Шаг 5 минут для удобства — 1-минутная точность избыточна.
    private var durationSection: some View {
        
        Section {
            // HStack — располагает два пикера горизонтально.
            HStack {
                
                // ────────────────────────────────────────
                // Пикер часов (0–12)
                // ────────────────────────────────────────
                
                // Picker — компонент выбора из списка значений.
                // "Hours" — accessibility-метка (для VoiceOver).
                // selection: $hours — привязка к @State переменной.
                Picker("Hours", selection: $hours) {
                    // ForEach создаёт пункты меню от 0 до 12.
                    // 0..<13 — диапазон от 0 до 12 включительно.
                    // .tag(h) — присваивает значение пункту меню.
                    // Когда пользователь выбирает "3 hr", hours = 3.
                    ForEach(0..<13) { h in
                        Text("\(h) hr").tag(h)
                    }
                }
                // .pickerStyle(.wheel) — стиль "колесо" (как в будильнике iOS).
                // Другие стили: .menu (выпадающее меню), .segmented (переключатель).
                // .wheel лучше всего подходит для выбора времени.
                
                // ────────────────────────────────────────
                // Пикер минут (0, 5, 10, ..., 55)
                // ────────────────────────────────────────
                
                Picker("Minutes", selection: $minutes) {
                    // stride(from:through:by:) — создаёт последовательность с шагом.
                    // from: 0 — начало
                    // through: 55 — конец (включительно)
                    // by: 5 — шаг
                    // Результат: 0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55
                    ForEach(Array(stride(from: 0, through: 55, by: 5)), id: \.self) { m in
                        Text("\(m) min").tag(m)
                    }
                }
            }
            
            // Итоговое время — показывает общее время в понятном формате.
            // Помогает пользователю быстро оценить выбранное время.
            if totalMinutes > 0 {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundStyle(.blue)
                    Text("Total: \(formattedTotalTime)")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .font(.subheadline)
            }
            
        } header: {
            Text("Daily Time Limit")
        } footer: {
            Text("How long the child can use the selected apps each day before they are blocked.")
        }
    }
    
    /// Секция с кнопкой открытия FamilyActivityPicker.
    ///
    /// При нажатии открывает системный экран выбора приложений Apple.
    /// Показывает текущее количество выбранных элементов.
    private var appsSelectionSection: some View {
        
        Section {
            // Кнопка выбора приложений.
            Button {
                // Устанавливаем флаг показа пикера.
                // .familyActivityPicker модификатор отреагирует и откроет системный экран.
                pickerIsPresented = true
            } label: {
                HStack {
                    // Иконка и текст кнопки.
                    Label("Select Apps & Categories", systemImage: "apps.iphone")
                    
                    Spacer()
                    
                    // Бейдж с количеством выбранных элементов.
                    // Показывается только если что-то выбрано.
                    if totalSelectedCount > 0 {
                        Text("\(totalSelectedCount)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.accentColor.opacity(0.15))
                            .foregroundStyle(Color.accentColor)
                            .clipShape(Capsule())
                    }
                    
                    // Иконка-стрелка — disclosure indicator.
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Apps & Categories")
        } footer: {
            Text("Choose which apps, categories, and websites this time limit applies to.")
        }
    }
    
    /// Секция со списком выбранных приложений, категорий и доменов.
    ///
    /// Отображает токены через Label(token) — Apple автоматически
    /// показывает иконку и название приложения/категории/домена.
    ///
    /// Эта секция видна только если hasSelection = true.
    private var selectedItemsSection: some View {
        
        Section {
            
            // ── Выбранные приложения ──
            // Перебираем все applicationTokens и создаём Label для каждого.
            if !selection.applicationTokens.isEmpty {
                ForEach(Array(selection.applicationTokens), id: \.self) { token in
                    // Label(token) — Apple отображает иконку и название приложения.
                    // Мы передаём зашифрованный токен, Apple расшифровывает и рисует.
                    Label(token)
                }
            }
            
            // ── Выбранные категории ──
            if !selection.categoryTokens.isEmpty {
                ForEach(Array(selection.categoryTokens), id: \.self) { token in
                    // Label(token) — Apple отображает иконку и название категории.
                    Label(token)
                }
            }
            
            // ── Выбранные веб-домены ──
            if !selection.webDomainTokens.isEmpty {
                ForEach(Array(selection.webDomainTokens), id: \.self) { token in
                    // Label(token) — Apple отображает favicon и доменное имя.
                    Label(token)
                }
            }
            
        } header: {
            // Заголовок секции с количеством.
            Text("Selected Items (\(totalSelectedCount))")
        }
    }
    
    /// Секция с кнопкой сохранения.
    ///
    /// Кнопка "Save" выполняет:
    /// 1. Валидацию формы
    /// 2. Создание объекта AppLimit
    /// 3. Вызов onSave callback
    /// 4. Запуск мониторинга
    /// 5. Закрытие экрана
    private var saveButtonSection: some View {
        
        Section {
            // Кнопка "Save" — главное действие экрана.
            Button {
                saveLimit()
            } label: {
                HStack {
                    Spacer()
                    
                    // Иконка + текст по центру.
                    Label("Save Limit", systemImage: "checkmark.circle.fill")
                        .fontWeight(.semibold)
                    
                    Spacer()
                }
            }
            // Отключаем кнопку, если форма невалидна.
            // Визуально: серый текст + нельзя нажать.
            // Пользователь видит, что нужно заполнить поля.
            .disabled(!isFormValid)
        }
    }
    
    // MARK: - Methods (Методы)
    
    /// Сохраняет лимит после валидации.
    ///
    /// Алгоритм:
    /// 1. Проверяет валидность формы
    /// 2. Если невалидна — показывает алерт с описанием проблемы
    /// 3. Если валидна:
    ///    a. Создаёт AppLimit из введённых данных
    ///    b. Вызывает onSave callback (LimitListView добавит лимит)
    ///    c. Запускает мониторинг через DeviceActivityService
    ///    d. Закрывает экран
    private func saveLimit() {
        
        // ── Валидация ──
        // Проверяем каждое поле и формируем понятное сообщение об ошибке.
        
        // 1. Проверка названия: не должно быть пустым.
        // .trimmingCharacters(in: .whitespacesAndNewlines) — убирает пробелы
        // и переносы строк в начале и конце. Нужно, чтобы "   " не считалось
        // валидным названием.
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            validationMessage = "Please enter a name for this limit."
            showValidationAlert = true
            return
        }
        
        // 2. Проверка времени: должно быть больше 0.
        // Лимит в 0 минут не имеет смысла — приложение будет
        // мгновенно заблокировано при открытии.
        guard totalMinutes > 0 else {
            validationMessage = "Please set a time limit greater than 0 minutes."
            showValidationAlert = true
            return
        }
        
        // 3. Проверка выбора: должно быть выбрано хоть что-то.
        // Без выбранных приложений лимит бесполезен.
        guard hasSelection else {
            validationMessage = "Please select at least one app, category, or website."
            showValidationAlert = true
            return
        }
        
        // ── Создание объекта AppLimit ──
        // Используем данные из формы для создания модели.
        let newLimit = AppLimit(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            minutesPerDay: totalMinutes,
            selection: selection,
            isEnabled: true  // Новый лимит сразу включён
        )
        
        print("✅ [LimitEditorView] Создан лимит: '\(newLimit.name)', \(newLimit.formattedLimit)")
        
        // ── Callback: передаём лимит в LimitListView ──
        // Вызываем замыкание, переданное при создании LimitEditorView.
        // LimitListView получит новый лимит и добавит в свой массив.
        onSave(newLimit)
        
        // ── Запуск мониторинга ──
        // Сразу запускаем мониторинг для нового лимита.
        // Apple начнёт считать время использования выбранных приложений.
        // Когда ребёнок использует их суммарно minutesPerDay минут,
        // DeviceActivityMonitor Extension получит уведомление.
        deviceActivityService.startDailyLimitMonitoring(for: newLimit)
        
        // ── Закрытие экрана ──
        // dismiss() закрывает текущий экран:
        // - Для NavigationLink → pop (возврат к предыдущему экрану)
        // - Для sheet → dismiss (закрытие модального окна)
        dismiss()
    }
    
    /// Форматирует общее время в читаемую строку.
    ///
    /// Примеры:
    /// - hours=1, minutes=30 → "1h 30m"
    /// - hours=2, minutes=0  → "2h"
    /// - hours=0, minutes=45 → "45m"
    private var formattedTotalTime: String {
        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Preview (Предпросмотр в Xcode)

/// Предпросмотр экрана редактирования лимита.
///
/// NavigationStack оборачивает LimitEditorView, чтобы в превью
/// был виден NavigationBar с заголовком.
///
/// onSave — пустое замыкание, потому что в превью нам не нужно
/// реально сохранять данные.
#Preview {
    NavigationStack {
        LimitEditorView { _ in }
            .environmentObject(DeviceActivityService.shared)
            .environmentObject(FamilyControlsService.shared)
    }
}
