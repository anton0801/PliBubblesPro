import Foundation
import SwiftUI
import Combine

// Data Models
struct Note: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var content: String
    var createdAt: Date
    var isFavorite: Bool = false
    
    static func ==(l: Note, r: Note) -> Bool {
        return l.id == r.id
    }
}

struct Reminder: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var time: Date
    var isRepeating: Bool
    var isCompleted: Bool
    
    static func ==(l: Reminder, r: Reminder) -> Bool {
        return l.id == r.id
    }
}

struct Event: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var date: Date
    
    static func ==(l: Event, r: Event) -> Bool {
        return l.id == r.id
    }
}

class DataManager: ObservableObject {
    @Published var notes: [Note] = []
    @Published var reminders: [Reminder] = []
    @Published var events: [Event] = []
    @Published var settings: Settings = Settings()
    
    private let notesKey = "notes"
    private let remindersKey = "reminders"
    private let eventsKey = "events"
    private let settingsKey = "settings"
    private var cancellables = Set<AnyCancellable>()
    
    struct Settings: Codable {
        var animationsEnabled: Bool = true
        var notificationsEnabled: Bool = true
    }
    
    init() {
        loadData()
        setupDebouncedSaving()
    }
    
    private func loadData() {
        if let notesData = UserDefaults.standard.data(forKey: notesKey),
           let decodedNotes = try? JSONDecoder().decode([Note].self, from: notesData) {
            notes = decodedNotes
        }
        if let remindersData = UserDefaults.standard.data(forKey: remindersKey),
           let decodedReminders = try? JSONDecoder().decode([Reminder].self, from: remindersData) {
            reminders = decodedReminders
        }
        if let eventsData = UserDefaults.standard.data(forKey: eventsKey),
           let decodedEvents = try? JSONDecoder().decode([Event].self, from: eventsData) {
            events = decodedEvents
        }
        if let settingsData = UserDefaults.standard.data(forKey: settingsKey),
           let decodedSettings = try? JSONDecoder().decode(Settings.self, from: settingsData) {
            settings = decodedSettings
        }
    }
    
    private func setupDebouncedSaving() {
        $notes
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink { [weak self] notes in
                if let data = try? JSONEncoder().encode(notes) {
                    UserDefaults.standard.set(data, forKey: self?.notesKey ?? "")
                }
            }
            .store(in: &cancellables)
        
        $reminders
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink { [weak self] reminders in
                if let data = try? JSONEncoder().encode(reminders) {
                    UserDefaults.standard.set(data, forKey: self?.remindersKey ?? "")
                }
            }
            .store(in: &cancellables)
        
        $events
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink { [weak self] events in
                if let data = try? JSONEncoder().encode(events) {
                    UserDefaults.standard.set(data, forKey: self?.eventsKey ?? "")
                }
            }
            .store(in: &cancellables)
        
        $settings
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink { [weak self] settings in
                if let data = try? JSONEncoder().encode(settings) {
                    UserDefaults.standard.set(data, forKey: self?.settingsKey ?? "")
                }
            }
            .store(in: &cancellables)
    }
    
    func addNote(_ note: Note) {
        notes.append(note)
    }
    
    func addReminder(_ reminder: Reminder) {
        reminders.append(reminder)
    }
    
    func addEvent(_ event: Event) {
        events.append(event)
    }
    
    func toggleReminderCompletion(_ reminder: Reminder) {
        if let index = reminders.firstIndex(where: { $0.id == reminder.id }) {
            reminders[index].isCompleted.toggle()
        }
    }
    
    func snoozeReminder(_ reminder: Reminder, by minutes: Int) {
        if let index = reminders.firstIndex(where: { $0.id == reminder.id }) {
            reminders[index].time = Calendar.current.date(byAdding: .minute, value: minutes, to: reminder.time)!
        }
    }
    
    func deleteReminder(_ reminder: Reminder) {
        reminders.removeAll { $0.id == reminder.id }
    }
    
    func toggleFavorite(note: Note) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes[index].isFavorite.toggle()
        }
    }
}

extension Color {
    static let darkViolet = Color(hex: "0D0D1A")
    static let nearBlack = Color(hex: "1A0D2E")
    static let deepPurple = Color(hex: "2A0D4A")
    static let neonPink = Color(hex: "FF4FBF")
    static let purpleGlow = Color(hex: "B84FFF")
    static let cyanGlow = Color(hex: "4FFFE0")
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .init(charactersIn: "#"))
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}

struct GlassmorphismModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.1))
                    .blur(radius: 10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.cyanGlow.opacity(0.3), lineWidth: 1)
                    )
            )
    }
}

struct EnhancedBubbleModifier: ViewModifier {
    @EnvironmentObject var dataManager: DataManager
    @State private var wobbleAngle: Double = 0
    
    func body(content: Content) -> some View {
        content
            .frame(width: 60, height: 60)
            .background(
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.neonPink, .purpleGlow]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            Circle()
                                .fill(Color.white.opacity(0.4))
                                .frame(width: 20, height: 20)
                                .offset(x: -15, y: -15)
                        )
                        .shadow(color: .neonPink.opacity(0.6), radius: 8, x: 0, y: 0)
                    Circle()
                        .stroke(Color.cyanGlow.opacity(0.2), lineWidth: 2)
                }
            )
            .clipShape(Circle())
            .rotationEffect(.degrees(dataManager.settings.animationsEnabled ? wobbleAngle : 0))
            .onAppear {
                if dataManager.settings.animationsEnabled {
                    withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                        wobbleAngle = 5
                    }
                }
            }
    }
}

extension View {
    func glassmorphism() -> some View {
        modifier(GlassmorphismModifier())
    }
    func enhancedBubbleStyle() -> some View {
        modifier(EnhancedBubbleModifier())
    }
}
