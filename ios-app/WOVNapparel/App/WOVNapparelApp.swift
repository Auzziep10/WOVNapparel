import SwiftUI
import FirebaseCore

@main
struct WOVNapparelApp: App {
    
    // Setup Firebase on app launch
    init() {
        // We will uncomment this once you drop the GoogleService-Info.plist into the project!
        // FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
