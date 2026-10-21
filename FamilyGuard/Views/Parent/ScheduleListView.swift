// ScheduleListView.swift
// FamilyGuard
//
// ЗАЧЕМ ЭТОТ ФАЙЛ:
// Это главный экран управления расписаниями блокировки.
//
// Расписание — это КОГДА блокировать приложения:
// - "Время сна" — 22:00 до 07:00 (ночью игры заблокированы)
// - "Школа" — 08:00 до 14:00 (во время уроков нельзя играть)
// - "Домашнее задание" — 16:00 до 18:00 (сначала уроки, потом игры)
//
// В отличие от ЛИМИТОВ, расписания работают по ВРЕМЕНИ СУТОК, а не по
// ДЛИТЕЛЬНОСТИ использования. Лимит = "1 час YouTube в день".
// Расписание = "с 22:00 до 07:00 YouTube заблокирован ПОЛНОСТЬЮ".
//
// СХЕМА ЭКРАНА:
//
//   ┌──────────────────────────────────────┐
//   │  📅 Schedules                   [+]  │  ← NavigationStack + Toolbar
//   ├──────────────────────────────────────┤
//   │                                      │
//   │  Quick Add:                           │
//   │  [🌙 Bedtime] [🏫 School] [📚 HW]   │  ← Кнопки пресетов
//   │                                      │
//   │  ┌──────────────────────────────┐    │
//   │  │ Bedtime       22:00 — 07:00  │    │  ← Расписание
//   │  │ [🟢 Enabled]                 │    │  ← Toggle
//   │  └──────────────────────────────┘    │
//   │                                      │
//   │  ┌──────────────────────────────┐    │
//   │  │ School        08:00 — 14:00  │    │
//   │  │ [🟢 Enabled]                 │    │
//   │  └──────────────────────────────┘    │
//   │                                      │
//   └──────────────────────────────────────┘
//
// ПРЕСЕТЫ (ШАБЛОНЫ):
// Для удобства родителей мы предлагаем готовые расписания.
// Кнопки "Add Bedtime", "Add School", "Add Homework" создают расписание
// с предустановленным временем. Родителю остаётся только выбрать приложения.
//
// СВЯЗЬ С ДРУГИМИ ФАЙЛАМИ:
// - BlockSchedule.swift — модель данных расписания (+ presets)
// - ScheduleEditorView.swift — экран создания/редактирования расписания
// - AppGroupStorage.swift — хранение расписаний в App Group
// - DeviceActivityService.swift — запуск/остановка мониторинга расписаний

import SwiftUI
import FamilyControls

/// Экран со списком всех расписаний блокировки.
///
/// Этот View реализует CRUD для расписаний блокировки:
/// - Create: кнопка "+" и пресеты
/// - Read: список с названиями и временными диапазонами
/// - Update: Toggle для вкл/выкл
/// - Delete: свайп влево
///
/// Использование:
/// ```swift
/// ScheduleListView()
///     .environmentObject(DeviceActivityService.shared)
/// ```
struct ScheduleListView: View {
    
    // MARK: - State Properties (Состояние)
    
    /// Массив расписаний, загруженный из AppGroupStorage.
    ///
    /// @State — локальное состояние View.
    /// Данные загружаются при появлении экрана (.onAppear)
    /// и обновляются при добавлении/удалении/toggle.
    @State private var schedules: [BlockSchedule] = []
    
    /// Флаг показа модального окна (sheet) для создания нового расписания.
    ///
    /// Когда true — поверх текущего экрана появляется ScheduleEditorView.
    /// Sheet можно закрыть свайпом вниз или кнопкой "Cancel".
    @State private var showEditorSheet: Bool = false
    
    /// Флаг показа пикера приложений для пресетов.
    ///
    /// Когда пользователь нажимает кнопку пресета (Bedtime, School, Homework),
    /// нам нужно сначала выбрать приложения для блокировки.
    /// Этот флаг контролирует показ FamilyActivityPicker.
    @State private var showPresetPicker: Bool = false
    
    /// Тип пресета, выбранный пользователем.
    ///
    /// Когда пользователь нажимает кнопку пресета, мы сохраняем тип
    /// (bedtime/school/homework) и открываем FamilyActivityPicker.
    /// После выбора приложений создаём расписание с этим типом.
    @State private var selectedPresetType: PresetType?
    
    /// Выбор приложений для пресета.
    ///
    /// FamilyActivitySelection заполняется через FamilyActivityPicker.
    /// После закрытия пикера используется для создания расписания-пресета.
    @State private var presetSelection: FamilyActivitySelection = FamilyActivitySelection()
    
    // MARK: - Environment (Зависимости из окружения)
    
    /// Сервис управления мониторингом DeviceActivity.
    ///
    /// Используется для запуска/остановки мониторинга расписаний.
    /// При включении Toggle → startScheduleMonitoring()
    /// При выключении → stopScheduleMonitoring()
    @EnvironmentObject var deviceActivityService: DeviceActivityService
    
    // MARK: - Enum: Тип пресета
    
    /// Перечисление типов пресетов (шаблонов) расписаний.
    ///
    /// Используется для определения, какой пресет создавать
    /// после выбора приложений в FamilyActivityPicker.
    ///
    /// CaseIterable — позволяет перебирать все случаи (case)
    /// через PresetType.allCases. Нужно для создания кнопок в UI.
    private enum PresetType: CaseIterable {
        /// Пресет "Время сна" — 22:00 до 07:00
        case bedtime
        /// Пресет "Школа" — 08:00 до 14:00
        case school
        /// Пресет "Домашнее задание" — 16:00 до 18:00
        case homework
        
        /// Название пресета для отображения на кнопке.
        var title: String {
            switch self {
            case .bedtime: return "Bedtime"
            case .school: return "School"
            case .homework: return "Homework"
            }
        }
        
        /// Иконка пресета (SF Symbol).
        var icon: String {
            switch self {
            case .bedtime: return "moon.fill"
            case .school: return "building.2.fill"
            case .homework: return "book.fill"
            }
        }
        
        /// Цвет пресета для визуального различения.
        var color: Color {
            switch self {
            case .bedtime: return .indigo
            case .school: return .orange
            case .homework: return .green
            }
        }
        
        /// Создаёт BlockSchedule на основе типа пресета и выбранных приложений.
        ///
        /// Каждый пресет имеет предустановленное время начала и окончания.
        /// Приложения для блокировки берутся из FamilyActivitySelection.
        ///
        /// - Parameter selection: Выбранные приложения/категории из пикера.
        /// - Returns: Готовый BlockSchedule.
        func createSchedule(with selection: FamilyActivitySelection) -> BlockSchedule {
            switch self {
            case .bedtime:
                return BlockSchedule.bedtimePreset(selection: selection)
            case .school:
                return BlockSchedule.schoolPreset(selection: selection)
            case .homework:
                return BlockSchedule.homeworkPreset(selection: selection)
            }
        }
    }
    
    // MARK: - Body (Основной интерфейс)
    
    var body: some View {
        
        // NavigationStack — контейнер навигации (iOS 16+).
        // Обеспечивает заголовок, кнопку "назад", toolbar.
        NavigationStack {
            
            Group {
                if schedules.isEmpty {
                    
                    // ────────────────────────────────────────
                    // ПУСТОЕ СОСТОЯНИЕ
                    // ────────────────────────────────────────
                    // Показывается, когда нет ни одного расписания.
                    emptyStateView
                    
                } else {
                    
                    // ────────────────────────────────────────
                    // СПИСОК РАСПИСАНИЙ
                    // ────────────────────────────────────────
                    schedulesListView
                }
            }
            // Заголовок навигации.
            .navigationTitle("Schedules")
            // Кнопка "+" в toolbar для создания нового расписания.
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    // Кнопка "+" — открывает sheet с ScheduleEditorView.
                    // В отличие от LimitListView (где используется NavigationLink),
                    // здесь используем sheet — модальное окно, которое появляется
                    // снизу. Это другой паттерн навигации в iOS.
                    Button {
                        showEditorSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            // ────────────────────────────────────────
            // SHEET: Модальное окно ScheduleEditorView
            // ────────────────────────────────────────
            // .sheet — показывает модальное окно поверх текущего экрана.
            // Пользователь может закрыть его свайпом вниз.
            //
            // isPresented: $showEditorSheet — контролирует показ/скрытие.
            // Когда пользователь нажимает "Save" в ScheduleEditorView,
            // тот вызывает dismiss(), и showEditorSheet автоматически = false.
            .sheet(isPresented: $showEditorSheet) {
                // NavigationStack нужен внутри sheet, чтобы ScheduleEditorView
                // мог показать NavigationBar с заголовком и кнопками.
                // Sheet — это ОТДЕЛЬНОЕ дерево навигации, не связанное с основным.
                NavigationStack {
                    ScheduleEditorView { newSchedule in
                        // Добавляем новое расписание в массив.
                        schedules.append(newSchedule)
                        // Сохраняем в AppGroupStorage.
                        saveSchedules()
                    }
                }
            }
            // ────────────────────────────────────────
            // FamilyActivityPicker для пресетов
            // ────────────────────────────────────────
            // Этот пикер открывается, когда пользователь нажимает
            // одну из кнопок пресетов (Bedtime, School, Homework).
            // После выбора приложений — автоматически создаётся расписание.
            .familyActivityPicker(
                isPresented: $showPresetPicker,
                selection: $presetSelection
            )
            // Реагируем на изменение presetSelection (после закрытия пикера).
            .onChange(of: presetSelection) { newSelection in
                // Создаём расписание из пресета, если пользователь выбрал приложения.
                handlePresetSelection(newSelection)
            }
            // Загрузка данных при появлении экрана.
            .onAppear {
                loadSchedules()
            }
        }
    }
    
    // MARK: - Subviews (Подвиды)
    
    /// Полный список расписаний с секцией пресетов сверху.
    private var schedulesListView: some View {
        
        List {
            
            // ────────────────────────────────────────
            // СЕКЦИЯ: Кнопки быстрого добавления (пресеты)
            // ────────────────────────────────────────
            // Пресеты — это готовые шаблоны расписаний с предустановленным временем.
            // Родителю нужно только выбрать приложения для блокировки.
            presetButtonsSection
            
            // ────────────────────────────────────────
            // СЕКЦИЯ: Список расписаний
            // ────────────────────────────────────────
            Section {
                // ForEach с $schedules — привязка для Toggle.
                // $schedule — Binding, позволяющий Toggle менять isEnabled.
                ForEach($schedules) { $schedule in
                    scheduleRow(schedule: $schedule)
                }
                // Свайп влево для удаления.
                .onDelete(perform: deleteSchedule)
            } header: {
                Text("Your Schedules")
            }
        }
        .listStyle(.insetGrouped)
    }
    
    /// Одна строка расписания в списке.
    ///
    /// Показывает:
    /// - Иконку (по типу расписания)
    /// - Название
    /// - Временной диапазон (например: "22:00 — 07:00")
    /// - Toggle вкл/выкл
    ///
    /// - Parameter schedule: Binding к конкретному расписанию в массиве.
    private func scheduleRow(schedule: Binding<BlockSchedule>) -> some View {
        
        HStack {
            
            // Иконка расписания с цветным кружком.
            // Выбираем иконку в зависимости от названия расписания.
            scheduleIcon(for: schedule.wrappedValue)
            
            // Информация о расписании.
            VStack(alignment: .leading, spacing: 4) {
                
                // Название расписания.
                Text(schedule.wrappedValue.name)
                    .font(.headline)
                    .foregroundStyle(schedule.wrappedValue.isEnabled ? .primary : .secondary)
                
                // Временной диапазон — например: "22:00 — 07:00"
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption)
                    Text(schedule.wrappedValue.formattedTimeRange)
                        .font(.subheadline)
                }
                .foregroundStyle(.secondary)
                
                // Индикатор повтора, если расписание повторяется.
                if schedule.wrappedValue.repeats {
                    HStack(spacing: 4) {
                        Image(systemName: "repeat")
                            .font(.caption2)
                        Text("Repeats daily")
                            .font(.caption)
                    }
                    .foregroundStyle(.tertiary)
                }
            }
            
            Spacer()
            
            // Toggle для включения/отключения расписания.
            Toggle("", isOn: schedule.isEnabled)
                .labelsHidden()
                .onChange(of: schedule.wrappedValue.isEnabled) { isEnabled in
                    // Сохраняем изменения.
                    saveSchedules()
                    
                    if isEnabled {
                        // Расписание ВКЛЮЧЕНО → запускаем мониторинг.
                        // Apple начнёт отслеживать время и вызовет
                        // intervalDidStart() когда наступит время начала.
                        deviceActivityService.startScheduleMonitoring(for: schedule.wrappedValue)
                    } else {
                        // Расписание ОТКЛЮЧЕНО → останавливаем мониторинг.
                        deviceActivityService.stopScheduleMonitoring(for: schedule.wrappedValue)
                    }
                }
        }
        .padding(.vertical, 4)
    }
    
    /// Иконка расписания — цветной кружок с иконкой внутри.
    ///
    /// Иконка зависит от названия расписания:
    /// - "Bedtime" → 🌙 луна (indigo)
    /// - "School" → 🏫 здание (orange)
    /// - "Homework" → 📚 книга (green)
    /// - Другое → 📅 календарь (blue)
    ///
    /// - Parameter schedule: Расписание, для которого выбирается иконка.
    /// - Returns: View с цветным кружком и иконкой.
    private func scheduleIcon(for schedule: BlockSchedule) -> some View {
        
        // Определяем иконку и цвет на основе названия.
        // lowercased() — приводим к нижнему регистру для надёжного сравнения.
        let iconName: String
        let iconColor: Color
        
        switch schedule.name.lowercased() {
        case let name where name.contains("bedtime") || name.contains("sleep"):
            iconName = "moon.fill"
            iconColor = .indigo
        case let name where name.contains("school"):
            iconName = "building.2.fill"
            iconColor = .orange
        case let name where name.contains("homework") || name.contains("study"):
            iconName = "book.fill"
            iconColor = .green
        default:
            iconName = "calendar.badge.clock"
            iconColor = .blue
        }
        
        // Возвращаем иконку в цветном кружке.
        return Image(systemName: iconName)
            .font(.body)
            // Цвет иконки — белый для контраста на цветном фоне.
            .foregroundStyle(.white)
            // Фиксированный размер рамки для единообразия.
            .frame(width: 36, height: 36)
            // Цветной круглый фон.
            .background(iconColor.gradient)
            // Обрезаем по кругу (круглая иконка).
            .clipShape(Circle())
    }
    
    /// Секция с кнопками пресетов (Bedtime, School, Homework).
    ///
    /// Пресеты — это быстрый способ создать расписание.
    /// При нажатии открывается FamilyActivityPicker для выбора приложений,
    /// затем автоматически создаётся расписание с предустановленным временем.
    private var presetButtonsSection: some View {
        
        Section {
            // ScrollView(.horizontal) — горизонтальная прокрутка.
            // Позволяет кнопкам уходить за пределы экрана, если их много.
            // showsIndicators: false — скрывает полосу прокрутки (cleaner UI).
            ScrollView(.horizontal, showsIndicators: false) {
                
                // HStack — горизонтальный стек для кнопок.
                HStack(spacing: 12) {
                    
                    // Создаём кнопку для каждого типа пресета.
                    // PresetType.allCases — все три случая: bedtime, school, homework.
                    ForEach(PresetType.allCases, id: \.title) { preset in
                        
                        // Кнопка пресета.
                        Button {
                            // Запоминаем тип пресета и открываем пикер приложений.
                            selectedPresetType = preset
                            // Очищаем предыдущий выбор перед открытием пикера.
                            presetSelection = FamilyActivitySelection()
                            showPresetPicker = true
                        } label: {
                            // Вертикальный стек: иконка + название.
                            VStack(spacing: 8) {
                                
                                // Иконка пресета в цветном кружке.
                                Image(systemName: preset.icon)
                                    .font(.title3)
                                    .foregroundStyle(.white)
                                    .frame(width: 44, height: 44)
                                    .background(preset.color.gradient)
                                    .clipShape(Circle())
                                
                                // Текст "Add Bedtime" / "Add School" / "Add Homework".
                                Text("Add \(preset.title)")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.primary)
                            }
                            // Внутренние отступы кнопки.
                            .padding(.vertical, 8)
                            .padding(.horizontal, 4)
                        }
                        .buttonStyle(.plain)
                    }
                }
                // Горизонтальные отступы для всего стека кнопок.
                .padding(.horizontal, 4)
            }
        } header: {
            Text("Quick Add")
        } footer: {
            Text("Tap a preset to quickly create a schedule with suggested times. You'll choose which apps to block.")
        }
    }
    
    /// Пустое состояние — когда нет ни одного расписания.
    ///
    /// Показывает:
    /// - Иконку календаря
    /// - Заголовок "No Schedules"
    /// - Описание, что это за экран
    /// - Кнопки пресетов для быстрого старта
    private var emptyStateView: some View {
        
        VStack(spacing: 24) {
            
            // ContentUnavailableView — стандартный Apple empty state.
            VStack(spacing: 16) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)
                Text("No Schedules")
                    .font(.title3)
                    .fontWeight(.bold)
                Text("Create schedules to automatically block apps during specific times like bedtime, school hours, or homework time.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                Button {
                    showEditorSheet = true
                } label: {
                    Text("Create Schedule")
                        .fontWeight(.semibold)
                }
                .buttonStyle(.borderedProminent)
            }
            
            // ────────────────────────────────────────
            // Кнопки пресетов в пустом состоянии
            // ────────────────────────────────────────
            // Даже в пустом состоянии мы показываем пресеты,
            // чтобы пользователь мог быстро начать работу.
            VStack(alignment: .leading, spacing: 12) {
                
                Text("Or start with a preset:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                
                // Горизонтальный стек кнопок пресетов.
                HStack(spacing: 12) {
                    ForEach(PresetType.allCases, id: \.title) { preset in
                        
                        // Кнопка пресета — расширенная версия для empty state.
                        Button {
                            selectedPresetType = preset
                            presetSelection = FamilyActivitySelection()
                            showPresetPicker = true
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: preset.icon)
                                    .font(.title2)
                                    .foregroundStyle(.white)
                                    .frame(width: 50, height: 50)
                                    .background(preset.color.gradient)
                                    .clipShape(Circle())
                                
                                Text(preset.title)
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            // Кнопка пресета занимает одинаковую ширину.
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
            // Внутренний отступ и фон для секции пресетов.
            .padding(.vertical, 16)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .padding(.horizontal)
        }
        // FamilyActivityPicker для пресетов в пустом состоянии.
        // Дублируем модификатор здесь на случай, если основной View
        // не имеет привязки (empty state — другая ветка if/else).
        // На практике модификаторы на Group работают для обеих ветвей,
        // но это дополнительная страховка.
    }
    
    // MARK: - Data Methods (Методы работы с данными)
    
    /// Загружает расписания из AppGroupStorage.
    ///
    /// Вызывается при появлении экрана (.onAppear).
    /// Гарантирует актуальность данных.
    private func loadSchedules() {
        schedules = AppGroupStorage.shared.loadSchedules()
        print("📋 [ScheduleListView] Загружено \(schedules.count) расписаний")
    }
    
    /// Сохраняет текущий массив расписаний в AppGroupStorage.
    ///
    /// Вызывается при любом изменении: добавление, удаление, toggle.
    private func saveSchedules() {
        AppGroupStorage.shared.saveSchedules(schedules)
        print("💾 [ScheduleListView] Сохранено \(schedules.count) расписаний")
    }
    
    /// Удаляет расписания по индексам (свайп влево).
    ///
    /// Алгоритм:
    /// 1. Останавливает мониторинг для каждого удаляемого расписания
    /// 2. Удаляет элементы из массива
    /// 3. Сохраняет обновлённый массив
    ///
    /// - Parameter offsets: Индексы удаляемых элементов.
    private func deleteSchedule(at offsets: IndexSet) {
        
        // Перед удалением останавливаем мониторинг.
        // Если не остановить — Apple продолжит блокировать приложения
        // по правилам уже удалённого расписания.
        for index in offsets {
            let schedule = schedules[index]
            
            if schedule.isEnabled {
                deviceActivityService.stopScheduleMonitoring(for: schedule)
            }
            
            print("🗑️ [ScheduleListView] Удаляем расписание: '\(schedule.name)'")
        }
        
        // Удаляем из массива.
        schedules.remove(atOffsets: offsets)
        
        // Сохраняем обновлённый массив.
        saveSchedules()
    }
    
    /// Обрабатывает выбор приложений для пресета.
    ///
    /// Вызывается через .onChange(of: presetSelection) после закрытия
    /// FamilyActivityPicker. Если пользователь выбрал приложения —
    /// создаём расписание из пресета и добавляем в массив.
    ///
    /// - Parameter selection: Новый выбор из FamilyActivityPicker.
    private func handlePresetSelection(_ selection: FamilyActivitySelection) {
        
        // Проверяем, что пользователь действительно выбрал приложения.
        // Если selection пустой — пользователь закрыл пикер без выбора.
        guard !selection.applicationTokens.isEmpty ||
              !selection.categoryTokens.isEmpty ||
              !selection.webDomainTokens.isEmpty else {
            // Пустой выбор — ничего не делаем.
            return
        }
        
        // Проверяем, что тип пресета был выбран.
        guard let presetType = selectedPresetType else {
            return
        }
        
        // Создаём расписание из пресета с выбранными приложениями.
        let newSchedule = presetType.createSchedule(with: selection)
        
        // Добавляем в массив.
        schedules.append(newSchedule)
        
        // Сохраняем в AppGroupStorage.
        saveSchedules()
        
        // Запускаем мониторинг для нового расписания.
        // Apple начнёт следить за временем и вызовет
        // intervalDidStart() когда наступит время начала.
        deviceActivityService.startScheduleMonitoring(for: newSchedule)
        
        print("✅ [ScheduleListView] Пресет '\(presetType.title)' создан: \(newSchedule.formattedTimeRange)")
        
        // Очищаем выбранный тип пресета.
        selectedPresetType = nil
    }
}

// MARK: - Preview (Предпросмотр в Xcode)

/// Предпросмотр экрана списка расписаний.
///
/// Для работы необходимо предоставить DeviceActivityService через environmentObject.
#Preview {
    ScheduleListView()
        .environmentObject(DeviceActivityService.shared)
}
