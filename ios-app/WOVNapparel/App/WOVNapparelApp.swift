import SwiftUI
import FirebaseCore

@main
struct WOVNapparelApp: App {
    
    // Setup Firebase on app launch
    init() {
        FirebaseApp.configure()
    }
    
    @StateObject private var appState = AppFlowState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}
