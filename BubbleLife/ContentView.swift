import SwiftUI

struct HomeView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showAddNote = false
    @State private var showAddReminder = false
    @State private var showAddEvent = false
    
    var body: some View {
        ZStack {
            EnhancedParticleBackground()
            
            VStack {
                // Header
                Text("Today, \(Date(), formatter: dateFormatter)")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                    .shadow(color: .cyanGlow.opacity(0.3), radius: 2)
                    .padding()
                
                Text(todaySummary)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                
                // Today’s List
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(todayItems) { item in
                            TodayItemView(item: item)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding()
                }
                .animation(.easeInOut, value: todayItems)
                
                // Quick Action Buttons
                HStack(spacing: 20) {
                    Button(action: { showAddNote = true }) {
                        VStack {
                            Image(systemName: "note.text")
                                .enhancedBubbleStyle()
                            Text("Add Note")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                    }
                    .accessibilityLabel("Add a new note")
                    
                    Button(action: { showAddReminder = true }) {
                        VStack {
                            Image(systemName: "bell")
                                .enhancedBubbleStyle()
                            Text("Add Reminder")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                    }
                    .accessibilityLabel("Add a new reminder")
                    
                    Button(action: { showAddEvent = true }) {
                        VStack {
                            Image(systemName: "calendar")
                                .enhancedBubbleStyle()
                            Text("Add Event")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                    }
                    .accessibilityLabel("Add a new event")
                }
                .padding(.vertical, 20)
                
                // Stats Widget
                HStack {
                    ForEach(0..<5) { index in
                        Circle()
                            .fill(index < completedToday ? Color.neonPink : Color.white.opacity(0.3))
                            .frame(width: 12, height: 12)
                    }
                    Text("\(completedToday)/5 tasks done today")
                        .font(.caption)
                        .foregroundColor(.white)
                }
                .padding(.bottom, 20)
                .glassmorphism()
            }
        }
        .sheet(isPresented: $showAddNote) { AddNoteView() }
        .sheet(isPresented: $showAddReminder) { AddReminderView() }
        .sheet(isPresented: $showAddEvent) { AddEventView(date: Date()) }
    }
    
    private var todayItems: [TodayItem] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let notes = dataManager.notes.map {
            TodayItem(id: $0.id, type: .note, title: $0.title, time: $0.createdAt)
        }
        let reminders = dataManager.reminders
            .filter { calendar.isDate($0.time, inSameDayAs: today) && !$0.isCompleted }
            .map { TodayItem(id: $0.id, type: .reminder, title: $0.title, time: $0.time) }
        let events = dataManager.events
            .filter { calendar.isDate($0.date, inSameDayAs: today) }
            .map { TodayItem(id: $0.id, type: .event, title: $0.title, time: $0.date) }
        
        return (notes + reminders + events).sorted { $0.time < $1.time }
    }
    
    private var completedToday: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return dataManager.reminders.filter { calendar.isDate($0.time, inSameDayAs: today) && $0.isCompleted }.count
    }
    
    private var todaySummary: String {
        let eventCount = dataManager.events.filter { Calendar.current.isDate($0.date, inSameDayAs: Date()) }.count
        let reminderCount = dataManager.reminders.filter { Calendar.current.isDate($0.time, inSameDayAs: Date()) && !$0.isCompleted }.count
        return NSLocalizedString("You have \(eventCount) events and \(reminderCount) reminders today", comment: "")
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter
    }()
}

struct TodayItemView: View {
    let item: TodayItem
    @EnvironmentObject var dataManager: DataManager
    @State private var isTapped = false
    
    var body: some View {
        HStack {
            Image(systemName: iconForType(item.type))
                .enhancedBubbleStyle()
            VStack(alignment: .leading) {
                Text(item.title)
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .font(.system(.body, design: .rounded))
                Text(item.time, style: .time)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            Spacer()
            if item.type == .reminder {
                Button(action: {
                    if let reminder = dataManager.reminders.first(where: { $0.id == item.id }) {
                        dataManager.toggleReminderCompletion(reminder)
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                    }
                }) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.cyanGlow)
                }
                .accessibilityLabel("Mark reminder as completed")
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.cyanGlow.opacity(0.2), lineWidth: 1)
        )
        .scaleEffect(isTapped ? 1.05 : 1.0)
        .animation(dataManager.settings.animationsEnabled ? .spring() : .none, value: isTapped)
        .onTapGesture {
            isTapped = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                isTapped = false
            }
        }
    }
    
    private func iconForType(_ type: TodayItem.ItemType) -> String {
        switch type {
        case .note: return "note.text"
        case .reminder: return "bell"
        case .event: return "calendar"
        }
    }
}

struct TodayItem: Identifiable, Equatable {
    let id: UUID
    let type: ItemType
    let title: String
    let time: Date
    
    enum ItemType {
        case note, reminder, event
    }
    
    static func ==(l: TodayItem, r: TodayItem) -> Bool {
        return l.id == r.id
    }
}

struct NotesView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var searchText = ""
    @State private var sortBy: SortOption = .newest
    @State private var showAddNote = false
    
    enum SortOption: String, CaseIterable {
        case newest = "Newest"
        case oldest = "Oldest"
        case favorites = "Favorites"
    }
    
    var body: some View {
        ZStack {
            EnhancedParticleBackground()
            
            VStack {
                Text(NSLocalizedString("Bubble Notes", comment: ""))
                    .font(.title.bold())
                    .foregroundColor(.white)
                    .shadow(color: .cyanGlow.opacity(0.3), radius: 2)
                    .padding()
                
                TextField(NSLocalizedString("Search notes", comment: ""), text: $searchText)
                    .padding()
                    .glassmorphism()
                    .foregroundColor(.white)
                    .padding(.horizontal)
                    .accessibilityLabel("Search notes")
                
                Picker(NSLocalizedString("Sort by", comment: ""), selection: $sortBy) {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Text(NSLocalizedString(option.rawValue, comment: "")).tag(option)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                if filteredNotes.isEmpty {
                    EmptyStateView(message: NSLocalizedString("You don’t have any notes yet — Tap + to add your first bubble.", comment: ""))
                } else {
                    ScrollView {
                        StaggeredGrid(items: filteredNotes, columns: 2, spacing: 20) { note in
                            NoteBubbleView(note: note)
                                .transition(.scale.combined(with: .opacity))
                        }
                        .padding()
                    }
                    .animation(dataManager.settings.animationsEnabled ? .easeInOut : .none, value: filteredNotes)
                }
                
                Spacer()
                
                Button(action: { showAddNote = true }) {
                    Image(systemName: "plus")
                        .enhancedBubbleStyle()
                }
                .accessibilityLabel("Add new note")
                .padding(.bottom, 20)
            }
        }
        .sheet(isPresented: $showAddNote) { AddNoteView() }
    }
    
    private var filteredNotes: [Note] {
        let sortedNotes = dataManager.notes.sorted {
            switch sortBy {
            case .newest: return $0.createdAt > $1.createdAt
            case .oldest: return $0.createdAt < $1.createdAt
            case .favorites: return $0.isFavorite && !$1.isFavorite
            }
        }
        if searchText.isEmpty {
            return sortedNotes
        } else {
            return sortedNotes.filter { $0.title.lowercased().contains(searchText.lowercased()) }
        }
    }
}

struct StaggeredGrid<Item: Identifiable, Content: View>: View {
    
    let items: [Item]
    let columns: Int
    let spacing: CGFloat
    let content: (Item) -> Content
    
    var body: some View {
        GeometryReader { geometry in
            let columnWidth = (geometry.size.width - spacing * CGFloat(columns - 1)) / CGFloat(columns)
            
            ScrollView {
                VStack(alignment: .leading, spacing: spacing) {
                    ForEach(0..<(items.count + columns - 1) / columns, id: \.self) { row in
                        HStack(spacing: spacing) {
                            ForEach(0..<columns, id: \.self) { column in
                                let index = row * columns + column
                                if index < items.count {
                                    content(items[index])
                                        .frame(width: columnWidth)
                                        .offset(y: column % 2 == 1 ? spacing / 2 : 0) // Stagger effect
                                } else {
                                    Spacer()
                                        .frame(width: columnWidth)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

extension View {
    subscript(index: Int) -> some View {
        AnyView(self)
    }
}

struct EmptyStateView: View {
    let message: String
    @EnvironmentObject var dataManager: DataManager
    @State private var bounceOffset: CGFloat = 0
    
    var body: some View {
        VStack {
            Image(systemName: "plus.circle.fill")
                .resizable()
                .frame(width: 80, height: 80)
                .enhancedBubbleStyle()
                .offset(y: bounceOffset)
                .animation(
                    dataManager.settings.animationsEnabled ?
                        .easeInOut(duration: 1).repeatForever(autoreverses: true) : .none,
                    value: bounceOffset
                )
                .onAppear {
                    if dataManager.settings.animationsEnabled {
                        bounceOffset = 10
                    }
                }
            
            Text(message)
                .foregroundColor(.white.opacity(0.7))
                .font(.system(.body, design: .rounded))
                .multilineTextAlignment(.center)
                .padding()
        }
        .padding(.top, 50)
    }
}

struct NoteBubbleView: View {
    let note: Note
    @EnvironmentObject var dataManager: DataManager
    @State private var isTapped = false
    
    var body: some View {
        VStack {
            ZStack {
                Image(systemName: "note.text")
                    .enhancedBubbleStyle()
                Button(action: {
                    dataManager.toggleFavorite(note: note)
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }) {
                    Image(systemName: note.isFavorite ? "star.fill" : "star")
                        .foregroundColor(.cyanGlow)
                        .offset(x: 25, y: -25)
                }
                .accessibilityLabel(note.isFavorite ? "Remove from favorites" : "Add to favorites")
            }
            .scaleEffect(isTapped ? 1.2 : 1.0)
            .animation(dataManager.settings.animationsEnabled ? .spring() : .none, value: isTapped)
            .onTapGesture {
                isTapped = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    isTapped = false
                }
            }
            Text(note.title)
                .font(.system(.caption, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 80)
        }
    }
}

struct AddNoteView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var content = ""
    
    var body: some View {
        ZStack {
            EnhancedParticleBackground()
            
            VStack {
                Text(NSLocalizedString("New Note", comment: ""))
                    .font(.title.bold())
                    .foregroundColor(.white)
                
                TextField(NSLocalizedString("Title", comment: ""), text: $title)
                    .padding()
                    .glassmorphism()
                    .foregroundColor(.white)
                
                TextEditor(text: $content)
                    .padding()
                    .glassmorphism()
                    .foregroundColor(.white)
                    .frame(height: 200)
                
                Button(action: {
                    if !title.isEmpty {
                        let note = Note(id: UUID(), title: title, content: content, createdAt: Date())
                        dataManager.addNote(note)
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        dismiss()
                    }
                }) {
                    Text(NSLocalizedString("Save", comment: ""))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.neonPink)
                        .cornerRadius(10)
                        .shadow(color: .neonPink.opacity(0.5), radius: 5)
                }
                .accessibilityLabel("Save note")
                .padding()
                
                Spacer()
            }
            .padding()
        }
    }
}

struct CalendarView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedDate = Date()
    @State private var showAddEvent = false
    
    var body: some View {
        ZStack {
            EnhancedParticleBackground()
            
            VStack {
                // Header with Navigation
                HStack {
                    Button(action: { selectedDate = Calendar.current.date(byAdding: .month, value: -1, to: selectedDate)! }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                    }
                    .accessibilityLabel("Previous month")
                    
                    Text(monthFormatter.string(from: selectedDate))
                        .font(.title.bold())
                        .foregroundColor(.white)
                        .shadow(color: .cyanGlow.opacity(0.3), radius: 2)
                    
                    Button(action: { selectedDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedDate)! }) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.white)
                    }
                    .accessibilityLabel("Next month")
                }
                .padding()
                
                // Weekday Headers
                HStack {
                    ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                        Text(day)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal)
                
                // Calendar Grid
                let days = calendarDays(for: selectedDate)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                    ForEach(days, id: \.self) { day in
                        DayBubbleView(date: day, selectedDate: selectedDate, isSelected: Calendar.current.isDate(day, inSameDayAs: selectedDate))
                            .onTapGesture {
                                selectedDate = day
                                UINotificationFeedbackGenerator().notificationOccurred(.success)
                            }
                    }
                }
                .padding()
                
                if eventsForSelectedDate.isEmpty {
                    EmptyStateView(message: NSLocalizedString("No events today — Tap + to add", comment: ""))
                } else {
                    ScrollView {
                        ForEach(eventsForSelectedDate) { event in
                            EventBubbleView(event: event)
                        }
                    }
                }
                
                Spacer()
                
                Button(action: { showAddEvent = true }) {
                    Image(systemName: "plus")
                        .enhancedBubbleStyle()
                }
                .accessibilityLabel("Add new event")
                .padding(.bottom, 20)
            }
        }
        .sheet(isPresented: $showAddEvent) { AddEventView(date: selectedDate) }
    }
    
    private var eventsForSelectedDate: [Event] {
        dataManager.events.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }
    
    private func calendarDays(for date: Date) -> [Date] {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        let year = calendar.component(.year, from: date)
        let startOfMonth = calendar.date(from: DateComponents(year: year, month: month, day: 1))!
        let range = calendar.range(of: .day, in: .month, for: startOfMonth)!
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        let offset = firstWeekday - 1
        var days: [Date] = []
        
        // Add days from previous month if needed
        if offset > 0 {
            let prevMonth = calendar.date(byAdding: .month, value: -1, to: startOfMonth)!
            let prevRange = calendar.range(of: .day, in: .month, for: prevMonth)!
            for i in (prevRange.count - offset + 1)...prevRange.count {
                days.append(calendar.date(from: DateComponents(year: calendar.component(.year, from: prevMonth), month: calendar.component(.month, from: prevMonth), day: i))!)
            }
        }
        
        // Add current month days
        days.append(contentsOf: (1...range.count).map { calendar.date(byAdding: .day, value: $0 - 1, to: startOfMonth)! })
        
        return days
    }
    
    private let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
}

struct DayBubbleView: View {
    let date: Date
    let selectedDate: Date
    let isSelected: Bool
    @EnvironmentObject var dataManager: DataManager
    @State private var isTapped = false
    
    var body: some View {
        let isToday = Calendar.current.isDate(date, inSameDayAs: Date())
        let isPast = date < Date()
        let isCurrentMonth = Calendar.current.isDate(date, equalTo: selectedDate, toGranularity: .month)
        
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: isToday ? [.neonPink, .purpleGlow] : [.neonPink.opacity(isCurrentMonth ? (isPast ? 0.5 : 1.0) : 0.3), .purpleGlow.opacity(isCurrentMonth ? (isPast ? 0.5 : 1.0) : 0.3)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 40, height: 40)
                .overlay(
                    Circle()
                        .fill(Color.white.opacity(0.4))
                        .frame(width: 10, height: 10)
                        .offset(x: -10, y: -10)
                )
                .shadow(color: isSelected ? .cyanGlow.opacity(0.7) : (isToday ? .neonPink.opacity(0.7) : .clear), radius: 5)
            
            Text("\(Calendar.current.component(.day, from: date))")
                .foregroundColor(.white)
                .font(.system(.caption, design: .rounded))
        }
        .scaleEffect(isTapped ? 1.2 : 1.0)
        .animation(dataManager.settings.animationsEnabled ? .spring() : .none, value: isTapped)
        .onTapGesture {
            isTapped = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                isTapped = false
            }
        }
    }
}

struct EventBubbleView: View {
    let event: Event
    @EnvironmentObject var dataManager: DataManager
    @State private var isTapped = false
    
    var body: some View {
        HStack {
            Image(systemName: "calendar")
                .enhancedBubbleStyle()
            Text(event.title)
                .foregroundColor(.white)
                .lineLimit(1)
                .font(.system(.body, design: .rounded))
            Spacer()
            Text(event.date, style: .time)
                .foregroundColor(.white.opacity(0.7))
                .font(.caption)
        }
        .padding()
        .glassmorphism()
        .scaleEffect(isTapped ? 1.05 : 1.0)
        .animation(dataManager.settings.animationsEnabled ? .spring() : .none, value: isTapped)
        .onTapGesture {
            isTapped = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                isTapped = false
            }
        }
    }
}

struct AddEventView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    let date: Date
    
    var body: some View {
        ZStack {
            EnhancedParticleBackground()
            
            VStack {
                Text(NSLocalizedString("New Event", comment: ""))
                    .font(.title.bold())
                    .foregroundColor(.white)
                
                TextField(NSLocalizedString("Title", comment: ""), text: $title)
                    .padding()
                    .glassmorphism()
                    .foregroundColor(.white)
                
                Button(action: {
                    if !title.isEmpty {
                        let event = Event(id: UUID(), title: title, date: date)
                        dataManager.addEvent(event)
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        dismiss()
                    }
                }) {
                    Text(NSLocalizedString("Save", comment: ""))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.neonPink)
                        .cornerRadius(10)
                        .shadow(color: .neonPink.opacity(0.5), radius: 5)
                }
                .accessibilityLabel("Save event")
                .padding()
                
                Spacer()
            }
            .padding()
        }
    }
}

struct RemindersView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showAddReminder = false
    
    var body: some View {
        ZStack {
            EnhancedParticleBackground()
            
            VStack {
                Text(NSLocalizedString("Bubble Reminders", comment: ""))
                    .font(.title.bold())
                    .foregroundColor(.white)
                    .shadow(color: .cyanGlow.opacity(0.3), radius: 2)
                    .padding()
                
                if dataManager.reminders.isEmpty {
                    EmptyStateView(message: NSLocalizedString("No reminders yet — Tap + to create", comment: ""))
                } else {
                    ScrollView {
                        ForEach(groupedReminders, id: \.date) { group in
                            VStack(alignment: .leading) {
                                Text(group.date, style: .date)
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding(.horizontal)
                                
                                ForEach(group.reminders) { reminder in
                                    ReminderBubbleView(reminder: reminder)
                                }
                            }
                        }
                    }
                }
                
                Spacer()
                
                Button(action: { showAddReminder = true }) {
                    Image(systemName: "plus")
                        .enhancedBubbleStyle()
                }
                .accessibilityLabel("Add new reminder")
                .padding(.bottom, 20)
            }
        }
        .sheet(isPresented: $showAddReminder) { AddReminderView() }
    }
    
    private var groupedReminders: [(date: Date, reminders: [Reminder])] {
        let calendar = Calendar.current
        let sortedReminders = dataManager.reminders.sorted { $0.time < $1.time }
        let grouped = Dictionary(grouping: sortedReminders) { reminder in
            calendar.startOfDay(for: reminder.time)
        }
        return grouped.map { (date: $0.key, reminders: $0.value) }.sorted { $0.date < $1.date }
    }
}

struct ReminderBubbleView: View {
    let reminder: Reminder
    @EnvironmentObject var dataManager: DataManager
    @State private var isTapped = false
    
    var body: some View {
        let isDue = reminder.time <= Date() && !reminder.isCompleted
        
        HStack {
            Image(systemName: "bell")
                .enhancedBubbleStyle()
                .overlay(
                    isDue && dataManager.settings.animationsEnabled ?
                        Circle()
                            .fill(Color.cyanGlow.opacity(0.3))
                            .frame(width: 80, height: 80)
                            .scaleEffect(isTapped ? 1.3 : 1.0)
                            .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isTapped) : nil
                )
                .onAppear {
                    if isDue && dataManager.settings.animationsEnabled {
                        isTapped = true
                    }
                }
            
            VStack(alignment: .leading) {
                Text(reminder.title)
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .font(.system(.body, design: .rounded))
                Text(reminder.time, style: .time)
                    .foregroundColor(.white.opacity(0.7))
                    .font(.caption)
            }
            Spacer()
            if reminder.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.cyanGlow)
            }
        }
        .padding()
        .glassmorphism()
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                dataManager.deleteReminder(reminder)
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
            } label: {
                Label("Delete", systemImage: "trash")
            }
            
            Button {
                dataManager.snoozeReminder(reminder, by: 30)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            } label: {
                Label("Snooze", systemImage: "clock")
            }
            .tint(.cyanGlow)
        }
        .swipeActions(edge: .leading) {
            Button {
                dataManager.toggleReminderCompletion(reminder)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            } label: {
                Label("Complete", systemImage: "checkmark")
            }
            .tint(.neonPink)
        }
        .scaleEffect(isTapped && !isDue ? 1.05 : 1.0)
        .animation(dataManager.settings.animationsEnabled ? .spring() : .none, value: isTapped)
        .onTapGesture {
            if !isDue {
                isTapped = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    isTapped = false
                }
            }
        }
    }
}

struct AddReminderView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var time = Date()
    @State private var isRepeating = false
    
    var body: some View {
        ZStack {
            EnhancedParticleBackground()
            
            VStack {
                Text(NSLocalizedString("New Reminder", comment: ""))
                    .font(.title.bold())
                    .foregroundColor(.white)
                
                TextField(NSLocalizedString("Title", comment: ""), text: $title)
                    .padding()
                    .glassmorphism()
                    .foregroundColor(.white)
                
                DatePicker(NSLocalizedString("Time", comment: ""), selection: $time, displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.compact)
                    .foregroundColor(.white)
                
                Toggle(NSLocalizedString("Repeat", comment: ""), isOn: $isRepeating)
                    .foregroundColor(.white)
                    .padding()
                    .glassmorphism()
                
                Button(action: {
                    if !title.isEmpty {
                        let reminder = Reminder(id: UUID(), title: title, time: time, isRepeating: isRepeating, isCompleted: false)
                        dataManager.addReminder(reminder)
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        dismiss()
                    }
                }) {
                    Text(NSLocalizedString("Save", comment: ""))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.neonPink)
                        .cornerRadius(10)
                        .shadow(color: .neonPink.opacity(0.5), radius: 5)
                }
                .accessibilityLabel("Save reminder")
                .padding()
                
                Spacer()
            }
            .padding()
        }
    }
}

struct StatisticsView: View {
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        ZStack {
            EnhancedParticleBackground()
            
            VStack {
                Text(NSLocalizedString("Bubble Stats", comment: ""))
                    .font(.title.bold())
                    .foregroundColor(.white)
                    .shadow(color: .cyanGlow.opacity(0.3), radius: 2)
                    .padding()
                
                if dataManager.notes.isEmpty && dataManager.reminders.isEmpty && dataManager.events.isEmpty {
                    EmptyStateView(message: NSLocalizedString("Your bubble stats will appear once you add notes, reminders, and events.", comment: ""))
                } else {
                    BubblePieChart()
                        .frame(height: 200)
                    
                    Text(NSLocalizedString("You popped \(totalCompleted) bubbles this week!", comment: ""))
                        .foregroundColor(.white)
                        .font(.system(.body, design: .rounded))
                        .padding()
                }
                
                Spacer()
            }
        }
    }
    
    private var totalCompleted: Int {
        dataManager.reminders.filter { $0.isCompleted }.count
    }
}

struct ProfileView: View {
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        ZStack {
            EnhancedParticleBackground()
            
            ScrollView {
                VStack(spacing: 20) {
                    // User Info Section
                    VStack {
                        Text(NSLocalizedString("Profile", comment: ""))
                            .font(.title.bold())
                            .foregroundColor(.white)
                            .shadow(color: .cyanGlow.opacity(0.3), radius: 2)
                            .padding(.top)
                        
                        Image(systemName: "person.circle")
                            .resizable()
                            .frame(width: 100, height: 100)
                            .enhancedBubbleStyle()
                        
                        Text(NSLocalizedString("Bubble User", comment: ""))
                            .font(.title2)
                            .foregroundColor(.white)
                        
                        Text(NSLocalizedString("Living the Bubble Life!", comment: ""))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding()
                    
                    // Statistics Section
                    VStack(spacing: 10) {
                        Text(NSLocalizedString("Your Stats", comment: ""))
                            .font(.title3.bold())
                            .foregroundColor(.white)
                            .shadow(color: .neonPink.opacity(0.3), radius: 2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        
                        if dataManager.notes.isEmpty && dataManager.reminders.isEmpty && dataManager.events.isEmpty {
                            EmptyStateView(message: NSLocalizedString("Your bubble stats will appear once you add notes, reminders, and events.", comment: ""))
                        } else {
                            BubblePieChart()
                                .frame(height: 200)
                                .padding()
                                .glassmorphism()
                            
                            Text(NSLocalizedString("You popped \(totalCompleted) bubbles this week!", comment: ""))
                                .foregroundColor(.white)
                                .font(.system(.body, design: .rounded))
                                .padding(.horizontal)
                        }
                        
                        // Quick Stats
                        VStack(alignment: .leading, spacing: 10) {
                            Text(NSLocalizedString("Total Notes: \(dataManager.notes.count)", comment: ""))
                                .foregroundColor(.white)
                            Text(NSLocalizedString("Reminders Completed: \(dataManager.reminders.filter { $0.isCompleted }.count)", comment: ""))
                                .foregroundColor(.white)
                            Text(NSLocalizedString("Events: \(dataManager.events.count)", comment: ""))
                                .foregroundColor(.white)
                        }
                        .padding()
                        .glassmorphism()
                    }
                    
                    // Achievements Section
                    VStack(spacing: 10) {
                        Text(NSLocalizedString("Achievements", comment: ""))
                            .font(.title3.bold())
                            .foregroundColor(.white)
                            .shadow(color: .neonPink.opacity(0.3), radius: 2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 20) {
                            ForEach(achievements, id: \.title) { achievement in
                                VStack {
                                    Image(systemName: achievement.icon)
                                        .enhancedBubbleStyle()
                                    Text(NSLocalizedString(achievement.title, comment: ""))
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(width: 100)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Settings Section
                    VStack(spacing: 10) {
                        Text(NSLocalizedString("Settings", comment: ""))
                            .font(.title3.bold())
                            .foregroundColor(.white)
                            .shadow(color: .neonPink.opacity(0.3), radius: 2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        
                        Toggle(NSLocalizedString("Animations", comment: ""), isOn: $dataManager.settings.animationsEnabled)
                            .foregroundColor(.white)
                            .padding()
                            .glassmorphism()
                            .accessibilityLabel("Toggle animations")
                        
                        Toggle(NSLocalizedString("Notifications", comment: ""), isOn: $dataManager.settings.notificationsEnabled)
                            .foregroundColor(.white)
                            .padding()
                            .glassmorphism()
                            .accessibilityLabel("Toggle notifications")
                        
                        Button(action: {}) {
                            Text(NSLocalizedString("Backup to iCloud", comment: ""))
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .glassmorphism()
                        }
                        .accessibilityLabel("Backup to iCloud")
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding(.bottom, 20)
            }
        }
    }
    
    private var achievements: [(title: String, icon: String)] {
        [
            (title: "7-Day Streak", icon: "flame"),
            (title: "50 Notes", icon: "note.text"),
            (title: "100 Reminders", icon: "bell")
        ]
    }
    
    private var totalCompleted: Int {
        dataManager.reminders.filter { $0.isCompleted }.count
    }
}

struct BubblePieChart: View {
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        GeometryReader { geometry in
            let radius = min(geometry.size.width, geometry.size.height) / 2
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let total = totalItems
            let segments = [
                (label: NSLocalizedString("Notes", comment: ""), value: dataManager.notes.count, color: Color.neonPink),
                (label: NSLocalizedString("Reminders", comment: ""), value: dataManager.reminders.count, color: Color.purpleGlow),
                (label: NSLocalizedString("Events", comment: ""), value: dataManager.events.count, color: Color.cyanGlow)
            ]
            
            ZStack {
                ForEach(0..<segments.count, id: \.self) { index in
                    let segment = segments[index]
                    let startAngle = angleFor(index: index, segments: segments, total: total)
                    let endAngle = angleFor(index: index + 1, segments: segments, total: total)
                    
                    Path { path in
                        path.move(to: center)
                        path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
                    }
                    .fill(segment.color)
                    .overlay(
                        Path { path in
                            path.move(to: center)
                            path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
                        }
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    )
                    .shadow(color: segment.color.opacity(0.5), radius: 5)
                    .scaleEffect(dataManager.settings.animationsEnabled ? (index == 0 ? 1.05 : 1.0) : 1.0)
                    .animation(
                        dataManager.settings.animationsEnabled ?
                            .easeInOut(duration: 1.5).repeatForever(autoreverses: true) : .none,
                        value: dataManager.settings.animationsEnabled
                    )
                    
                    Text(segment.label)
                        .font(.caption)
                        .foregroundColor(.white)
                        .position(labelPosition(for: startAngle, endAngle: endAngle, radius: radius * 1.2, center: center))
                }
            }
        }
    }
    
    private var totalItems: Int {
        max(dataManager.notes.count + dataManager.reminders.count + dataManager.events.count, 1) // Avoid division by zero
    }
    
    private func angleFor(index: Int, segments: [(label: String, value: Int, color: Color)], total: Int) -> Angle {
        let totalValue = segments.prefix(index).reduce(0) { $0 + $1.value }
        return .degrees(360 * Double(totalValue) / Double(total))
    }
    
    private func labelPosition(for startAngle: Angle, endAngle: Angle, radius: CGFloat, center: CGPoint) -> CGPoint {
        let midAngle = (startAngle + endAngle) / 2
        let x = center.x + radius * cos(CGFloat(midAngle.radians))
        let y = center.y + radius * sin(CGFloat(midAngle.radians))
        return CGPoint(x: x, y: y)
    }
}

struct SettingsView: View {
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        ZStack {
            EnhancedParticleBackground()
            
            VStack {
                Text(NSLocalizedString("Settings", comment: ""))
                    .font(.title.bold())
                    .foregroundColor(.white)
                    .shadow(color: .cyanGlow.opacity(0.3), radius: 2)
                    .padding()
                
                Toggle(NSLocalizedString("Animations", comment: ""), isOn: $dataManager.settings.animationsEnabled)
                    .foregroundColor(.white)
                    .padding()
                    .glassmorphism()
                
                Toggle(NSLocalizedString("Notifications", comment: ""), isOn: $dataManager.settings.notificationsEnabled)
                    .foregroundColor(.white)
                    .padding()
                    .glassmorphism()
                
                Button(action: {}) {
                    Text(NSLocalizedString("Backup to iCloud", comment: ""))
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .glassmorphism()
                }
                .accessibilityLabel("Backup to iCloud")
                
                Spacer()
            }
        }
    }
}
