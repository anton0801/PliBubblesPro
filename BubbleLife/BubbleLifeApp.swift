import SwiftUI

@main
struct BubbleLifeApp: App {
    @StateObject private var dataManager = DataManager()
    
    var body: some Scene {
        WindowGroup {
            TabView {
                HomeView()
                    .tabItem { Label(NSLocalizedString("Home", comment: ""), systemImage: "house") }
//                NotesView()
//                    .tabItem { Label(NSLocalizedString("Notes", comment: ""), systemImage: "note.text") }
                CalendarView()
                    .tabItem { Label(NSLocalizedString("Calendar", comment: ""), systemImage: "calendar") }
                RemindersView()
                    .tabItem { Label(NSLocalizedString("Reminders", comment: ""), systemImage: "bell") }
                ProfileView()
                    .tabItem { Label(NSLocalizedString("Profile", comment: ""), systemImage: "person") }
            }
            .accentColor(.neonPink)
            .environmentObject(dataManager)
            .preferredColorScheme(.dark)
        }
    }
}
