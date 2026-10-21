// ScheduleEditorView.swift
// FamilyGuard
//
// ЗАЧЕМ ЭТОТ ФАЙЛ:
// Экран создания и редактирования расписания блокировки.
//
// Расписание — это правило "КОГДА блокировать и ЧТО блокировать".
// Примеры расписаний:
//   • "Время сна" — с 22:00 до 07:00 (блокируем все игры и соцсети)
//   • "Школа" — с 08:00 до 14:00 (блокируем развлечения)
//   • "Домашнее задание" — с 16:00 до 18:00 (блокируем TikTok)
//
// КАК РАБОТАЕТ ЭТОТ ЭКРАН:
//
// 1. Родитель вводит НАЗВАНИЕ расписания (например: "Bedtime")
// 2. Родитель выбирает ВРЕМЯ НАЧАЛА через DatePicker (например: 22:00)
// 3. Родитель выбирает ВРЕМЯ КОНЦА через DatePicker (например: 07:00)
// 4. Родитель выбирает ПРИЛОЖЕНИЯ через FamilyActivityPicker
//    (Apple показывает системный пикер с иконками приложений)
// 5. Родитель выбирает ПРЕДУПРЕЖДЕНИЕ (за сколько минут до начала предупредить)
// 6. Родитель решает, повторять ли расписание каждый день
// 7. Нажимает "Save" → создаётся модель BlockSchedule →
//    сохраняется в AppGroupStorage → запускается мониторинг
//
// АРХИТЕКТУРА:
// Этот View использует @EnvironmentObject для доступа к DeviceActivityService,
// который управляет мониторингом. Когда пользователь нажимает "Save",
// мы создаём BlockSchedule, сохраняем его в общее хранилище (App Group),
// и запускаем мониторинг через DeviceActivityCenter.
//
// ВАЖНО О DatePicker И МОДЕЛИ BlockSchedule:
// DatePicker возвращает полный Date (дата + время).
// Но модель BlockSchedule хранит только hour и minute (Int).
// Поэтому мы используем Calendar.current.component(), чтобы
// извлечь час и минуту из Date, игнорируя дату.

import SwiftUI
import FamilyControls

/// Экран создания/редактирования расписания блокировки.
///
/// Родитель заполняет все параметры расписания и нажимает "Save".
/// При сохранении создаётся BlockSchedule и запускается мониторинг.
///
/// Используется как sheet (модальный экран) — после сохранения
/// автоматически закрывается через dismiss().
struct ScheduleEditorView: View {
    var onSave: ((BlockSchedule) -> Void)? = nil
    
    // MARK: - Environment
    
    /// dismiss — функция закрытия текущего модального экрана.
    ///
    /// Когда пользователь нажимает "Save" или "Cancel",
    /// мы вызываем dismiss(), чтобы вернуться на предыдущий экран.
    /// SwiftUI автоматически предоставляет эту функцию через @Environment.
    @Environment(\.dismiss) var dismiss
    
    /// Сервис управления мониторингом DeviceActivity.
    ///
    /// Через него мы запускаем мониторинг расписания после сохранения.
    /// @EnvironmentObject означает, что этот объект передаётся через
    /// иерархию View (от родительского View к дочернему).
    /// Если объект не был передан — приложение упадёт с ошибкой.
    @EnvironmentObject var deviceActivityService: DeviceActivityService
    
    // MARK: - State Properties (Состояние формы)
    
    /// Название расписания, введённое пользователем.
    ///
    /// @State означает, что SwiftUI "владеет" этим значением и
    /// автоматически перерисовывает View при его изменении.
    /// Пользователь вводит текст в TextField, и name обновляется автоматически.
    @State var name: String = ""
    
    /// Время начала расписания.
    ///
    /// DatePicker возвращает полный Date (дата + время), но нам нужны
    /// только часы и минуты. При сохранении мы извлечём hour и minute
    /// через Calendar.current.component(.hour, from: startTime).
    ///
    /// По умолчанию — 22:00 (типичное "время сна").
    /// Calendar.current создаёт Date из компонентов (hour: 22, minute: 0).
    @State var startTime: Date = Calendar.current.date(
        from: DateComponents(hour: 22, minute: 0)
    ) ?? Date()
    
    /// Время окончания расписания.
    ///
    /// По умолчанию — 07:00 (типичное "утро").
    /// Может быть РАНЬШЕ startTime — тогда расписание переходит через полночь.
    /// Например: 22:00 → 07:00 (ночное расписание).
    @State var endTime: Date = Calendar.current.date(
        from: DateComponents(hour: 7, minute: 0)
    ) ?? Date()
    
    /// Выбранные приложения и категории для блокировки.
    ///
    /// FamilyActivitySelection — это структура Apple, содержащая:
    /// - applicationTokens: зашифрованные токены приложений
    /// - categoryTokens: зашифрованные токены категорий
    /// - webDomainTokens: зашифрованные токены веб-доменов
    ///
    /// Мы НЕ видим настоящих названий или bundle ID приложений.
    /// Apple защищает приватность: мы работаем только с токенами.
    /// Но SwiftUI умеет отображать иконки/названия через Label(token).
    @State var selection = FamilyActivitySelection()
    
    /// Предупреждение за N минут до начала расписания.
    ///
    /// Когда выбрано 15 минут и расписание начинается в 22:00,
    /// ребёнок получит уведомление в 21:45: "Bedtime starts in 15 minutes".
    ///
    /// Доступные варианты: 5, 10, 15, 30 минут.
    @State var warningMinutes: Int = 15
    
    /// Повторяется ли расписание каждый день.
    ///
    /// true (по умолчанию): расписание срабатывает каждый день.
    /// false: расписание срабатывает один раз и больше не повторяется.
    ///
    /// Для большинства случаев (школа, сон) нужен повтор.
    @State var repeats: Bool = true
    
    /// Флаг отображения FamilyActivityPicker.
    ///
    /// Когда isPickerPresented = true, SwiftUI показывает системный
    /// пикер Apple для выбора приложений. Мы не можем изменить его
    /// внешний вид — это требование Apple для защиты приватности.
    @State private var isPickerPresented: Bool = false
    
    // MARK: - Constants
    
    /// Доступные варианты предупреждения (в минутах).
    ///
    /// Родитель выбирает один из этих вариантов в Picker.
    /// Значение определяет, за сколько минут до начала расписания
    /// будет отправлено предупреждающее уведомление.
    private let warningOptions: [Int] = [5, 10, 15, 30]
    
    // MARK: - Body
    
    var body: some View {
        
        /// NavigationStack — контейнер навигации SwiftUI.
        /// Он создаёт navigation bar с заголовком и позволяет
        /// использовать .navigationTitle() и .toolbar().
        NavigationStack {
            
            /// Form — специальный контейнер SwiftUI для форм ввода.
            /// Автоматически группирует элементы в секции (Section)
            /// и применяет системный стиль (скруглённые углы, разделители).
            Form {
                
                // ─── Секция 1: Название расписания ───
                
                /// Section создаёт визуальную группу элементов с заголовком.
                /// В iOS формах секции разделены серым пространством.
                Section {
                    /// TextField — поле ввода текста.
                    ///
                    /// "Schedule Name" — это placeholder (подсказка), которая
                    /// исчезает, когда пользователь начинает вводить текст.
                    /// text: $name — двусторонняя привязка (binding).
                    /// Когда пользователь вводит текст, name обновляется.
                    /// Когда name меняется программно, TextField тоже обновляется.
                    TextField("Schedule Name", text: $name)
                } header: {
                    /// Заголовок секции — отображается серым шрифтом
                    /// над содержимым секции в стиле iOS Settings.
                    Text("Name")
                }
                
                // ─── Секция 2: Выбор времени начала и конца ───
                
                Section {
                    /// DatePicker — системный элемент выбора времени.
                    ///
                    /// displayedComponents: .hourAndMinute означает, что
                    /// DatePicker показывает ТОЛЬКО часы и минуты (без даты).
                    /// Это именно то, что нам нужно: "расписание с 22:00 до 07:00".
                    ///
                    /// selection: $startTime — двусторонняя привязка.
                    /// Когда пользователь крутит колёсико — startTime обновляется.
                    DatePicker(
                        "Start Time",
                        selection: $startTime,
                        displayedComponents: .hourAndMinute
                    )
                    
                    /// Второй DatePicker для времени окончания.
                    /// Работает аналогично startTime.
                    ///
                    /// ВАЖНО: endTime может быть РАНЬШЕ startTime.
                    /// Например: start = 22:00, end = 07:00.
                    /// Это означает "расписание переходит через полночь".
                    /// Apple DeviceActivitySchedule поддерживает это автоматически.
                    DatePicker(
                        "End Time",
                        selection: $endTime,
                        displayedComponents: .hourAndMinute
                    )
                } header: {
                    Text("Time Range")
                } footer: {
                    /// Footer — текст под секцией. Используется для пояснений.
                    /// Мелкий серый шрифт — стандарт iOS Settings.
                    Text("The schedule will block selected apps between the start and end times. Overnight schedules (e.g., 10 PM — 7 AM) are supported.")
                }
                
                // ─── Секция 3: Выбор приложений для блокировки ───
                
                Section {
                    /// Кнопка, которая открывает FamilyActivityPicker.
                    ///
                    /// FamilyActivityPicker — это СИСТЕМНЫЙ пикер Apple.
                    /// Мы не можем встроить его напрямую в Form.
                    /// Вместо этого используем модификатор .familyActivityPicker(),
                    /// который показывает его как sheet (модальный экран).
                    Button {
                        /// Устанавливаем флаг, который запускает показ пикера.
                        isPickerPresented = true
                    } label: {
                        /// Label — элемент SwiftUI с иконкой и текстом.
                        /// "plus.app" — это SF Symbol (системная иконка Apple).
                        /// SF Symbols — бесплатная библиотека 5000+ иконок от Apple.
                        Label("Select Apps & Categories", systemImage: "plus.app")
                    }
                    
                    // ─── Отображение выбранных приложений ───
                    
                    /// Проверяем, выбраны ли приложения.
                    /// applicationTokens — это Set<ApplicationToken>.
                    /// Каждый token представляет одно приложение.
                    if !selection.applicationTokens.isEmpty {
                        /// VStack — вертикальный контейнер.
                        /// alignment: .leading — элементы выравниваются по левому краю.
                        /// spacing: 4 — расстояние между элементами (4 пункта).
                        VStack(alignment: .leading, spacing: 4) {
                            /// Подзаголовок "Applications" серым мелким шрифтом.
                            Text("Applications")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            /// ForEach перебирает все выбранные токены приложений.
                            ///
                            /// id: \.self — каждый ApplicationToken сам является
                            /// уникальным идентификатором (Hashable).
                            ///
                            /// Array(...) преобразует Set в Array, чтобы ForEach
                            /// мог итерировать по нему.
                            ForEach(Array(selection.applicationTokens), id: \.self) { token in
                                /// Label(token) — МАГИЯ SwiftUI + FamilyControls!
                                ///
                                /// SwiftUI умеет автоматически отображать
                                /// иконку и название приложения из токена.
                                /// Мы НЕ знаем, что это за приложение
                                /// (Apple защищает приватность), но SwiftUI
                                /// рисует правильную иконку и название.
                                Label(token)
                                    .font(.callout)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    
                    // ─── Отображение выбранных категорий ───
                    
                    /// Аналогично приложениям, но для категорий.
                    /// Категория — это группа приложений (например: "Games", "Social").
                    if !selection.categoryTokens.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Categories")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            ForEach(Array(selection.categoryTokens), id: \.self) { token in
                                /// Label(token) для категории показывает
                                /// иконку категории и её название
                                /// (например: иконка геймпада + "Games").
                                Label(token)
                                    .font(.callout)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Apps to Block")
                } footer: {
                    Text("Choose which apps and categories will be blocked during this schedule.")
                }
                
                // ─── Секция 4: Настройка предупреждения ───
                
                Section {
                    /// Picker — системный элемент выбора из нескольких вариантов.
                    ///
                    /// selection: $warningMinutes — текущий выбранный вариант.
                    /// Когда пользователь выбирает другой вариант, warningMinutes
                    /// автоматически обновляется.
                    Picker("Warn Before", selection: $warningMinutes) {
                        /// ForEach перебирает массив warningOptions [5, 10, 15, 30].
                        ///
                        /// id: \.self — каждое число Int само является
                        /// уникальным идентификатором.
                        ForEach(warningOptions, id: \.self) { minutes in
                            /// Text("\(minutes) minutes") — текст для каждого варианта.
                            /// .tag(minutes) — привязывает этот вариант к значению.
                            /// Когда пользователь выбирает "15 minutes",
                            /// warningMinutes = 15.
                            Text("\(minutes) minutes").tag(minutes)
                        }
                    }
                } header: {
                    Text("Warning")
                } footer: {
                    Text("A notification will be sent this many minutes before the schedule starts.")
                }
                
                // ─── Секция 5: Настройка повтора ───
                
                Section {
                    /// Toggle — переключатель (вкл/выкл).
                    ///
                    /// isOn: $repeats — двусторонняя привязка.
                    /// Когда пользователь переключает тумблер, repeats
                    /// автоматически меняется на true/false.
                    Toggle("Repeat Daily", isOn: $repeats)
                } footer: {
                    Text("When enabled, this schedule will automatically repeat every day.")
                }
                
                // ─── Секция 6: Кнопка "Save" ───
                
                Section {
                    /// Кнопка сохранения расписания.
                    ///
                    /// При нажатии:
                    /// 1. Извлекаем hour и minute из Date через Calendar
                    /// 2. Создаём модель BlockSchedule
                    /// 3. Загружаем существующие расписания из AppGroupStorage
                    /// 4. Добавляем новое расписание в массив
                    /// 5. Сохраняем обновлённый массив в AppGroupStorage
                    /// 6. Запускаем мониторинг через DeviceActivityService
                    /// 7. Закрываем модальный экран
                    Button {
                        saveSchedule()
                    } label: {
                        HStack {
                            Spacer()
                            
                            /// Label с иконкой "checkmark.circle.fill" (зелёная галочка).
                            Label("Save Schedule", systemImage: "checkmark.circle.fill")
                                .font(.headline)
                            
                            Spacer()
                        }
                    }
                    /// .disabled() — делает кнопку неактивной (серой),
                    /// если условие true.
                    ///
                    /// Кнопка неактивна, если:
                    /// - name пустой (пользователь не ввёл название)
                    /// - Нет выбранных приложений И нет выбранных категорий
                    ///
                    /// .trimmingCharacters(in: .whitespaces) — удаляет пробелы
                    /// в начале и конце строки, чтобы "   " не считалось названием.
                    .disabled(
                        name.trimmingCharacters(in: .whitespaces).isEmpty ||
                        (selection.applicationTokens.isEmpty && selection.categoryTokens.isEmpty)
                    )
                }
            }
            
            // ─── Navigation Bar ───
            
            /// .navigationTitle — заголовок экрана в navigation bar.
            .navigationTitle("New Schedule")
            
            /// .navigationBarTitleDisplayMode(.inline) — компактный заголовок
            /// (в одну строку), а не большой (large title). Для модальных
            /// экранов обычно используется .inline.
            .navigationBarTitleDisplayMode(.inline)
            
            /// .toolbar — добавляет кнопки в navigation bar.
            .toolbar {
                /// ToolbarItem(placement: .cancellationAction) — кнопка "Cancel"
                /// слева в navigation bar. Это стандартное расположение для
                /// кнопки отмены в iOS.
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        /// Закрываем модальный экран без сохранения.
                        dismiss()
                    }
                }
            }
            
            // ─── FamilyActivityPicker Modifier ───
            
            /// .familyActivityPicker — модификатор, который показывает
            /// системный пикер Apple для выбора приложений.
            ///
            /// isPresented: $isPickerPresented — когда true, пикер открывается.
            /// selection: $selection — двусторонняя привязка.
            ///
            /// Когда пользователь выбирает приложения в пикере и нажимает "Done",
            /// selection автоматически обновляется с новыми токенами.
            /// isPickerPresented автоматически становится false (пикер закрывается).
            ///
            /// ВАЖНО: Этот пикер — СИСТЕМНЫЙ. Мы не можем изменить его внешний
            /// вид, фильтры или поведение. Apple контролирует его полностью.
            /// Это сделано для защиты приватности — приложение не может
            /// программно узнать, какие приложения установлены на устройстве.
            .familyActivityPicker(
                isPresented: $isPickerPresented,
                selection: $selection
            )
        }
    }
    
    // MARK: - Save Logic
    
    /// Сохраняет расписание и запускает мониторинг.
    ///
    /// Последовательность действий:
    /// 1. Извлекаем час и минуту из Date объектов startTime/endTime
    /// 2. Создаём модель BlockSchedule с извлечёнными значениями
    /// 3. Загружаем массив существующих расписаний из App Group
    /// 4. Добавляем новое расписание в массив
    /// 5. Сохраняем обновлённый массив обратно в App Group
    /// 6. Запускаем мониторинг нового расписания
    /// 7. Закрываем модальный экран
    private func saveSchedule() {
        
        // ─── Шаг 1: Извлечение часа и минуты из Date ───
        
        /// Calendar.current — текущий календарь устройства.
        /// .component(.hour, from: startTime) — извлекает час из Date.
        ///
        /// ПОЧЕМУ ЭТО НУЖНО:
        /// DatePicker возвращает полный Date (например: 2024-01-15 22:30:00 UTC).
        /// Но модель BlockSchedule хранит только hour (Int) и minute (Int).
        /// Мы не храним дату — нас интересует только ВРЕМЯ (22:30).
        ///
        /// Calendar учитывает часовой пояс устройства, поэтому
        /// "22:30" будет правильным для любого часового пояса.
        let startHour = Calendar.current.component(.hour, from: startTime)
        let startMinute = Calendar.current.component(.minute, from: startTime)
        let endHour = Calendar.current.component(.hour, from: endTime)
        let endMinute = Calendar.current.component(.minute, from: endTime)
        
        // ─── Шаг 2: Создание модели BlockSchedule ───
        
        /// Создаём новую модель расписания с введёнными параметрами.
        ///
        /// UUID генерируется автоматически (по умолчанию в init).
        /// createdAt = Date() (текущее время) — по умолчанию в init.
        /// isEnabled = true — по умолчанию в init (расписание сразу активно).
        let schedule = BlockSchedule(
            name: name.trimmingCharacters(in: .whitespaces),
            startHour: startHour,
            startMinute: startMinute,
            endHour: endHour,
            endMinute: endMinute,
            selection: selection,
            isEnabled: true,
            repeats: repeats,
            warningMinutesBefore: warningMinutes
        )
        
        // ─── Шаг 3–5: Сохранение в AppGroupStorage ───
        
        /// Загружаем текущий массив расписаний из App Group.
        /// Если расписаний ещё нет — loadSchedules() вернёт пустой массив.
        var existingSchedules = AppGroupStorage.shared.loadSchedules()
        
        /// Добавляем новое расписание в массив.
        existingSchedules.append(schedule)
        
        /// Сохраняем обновлённый массив обратно в App Group.
        /// Теперь и основное приложение, и DeviceActivityMonitor Extension
        /// смогут прочитать это расписание.
        AppGroupStorage.shared.saveSchedules(existingSchedules)
        
        // ─── Шаг 6: Запуск мониторинга ───
        
        /// deviceActivityService.startScheduleMonitoring() создаёт
        /// DeviceActivitySchedule и регистрирует его через DeviceActivityCenter.
        ///
        /// После этого Apple начнёт следить за временем:
        /// - Когда наступит startTime → Extension получит intervalDidStart()
        /// - Когда наступит endTime → Extension получит intervalDidEnd()
        deviceActivityService.startScheduleMonitoring(for: schedule)
        
        // ─── Шаг 7: Закрытие модального экрана ───
        
        /// dismiss() закрывает текущий sheet (модальный экран).
        /// Пользователь вернётся на предыдущий экран (например, Parent Dashboard).
        onSave?(schedule)
        dismiss()
    }
}
