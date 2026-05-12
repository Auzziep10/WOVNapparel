import SwiftUI

enum AppRoute: Equatable {
    case onboarding
    case dashboard
    case captureFlow
    case tryOn(techPackId: String)
}

class AppFlowState: ObservableObject {
    @Published var currentRoute: AppRoute = .onboarding
    
    // We will sync this with Firestore shortly
    @Published var hasProfile: Bool = false
    @Published var userName: String = ""
    @Published var userMetrics: [String: Double] = [:]
    
    func completeOnboarding() {
        hasProfile = true
        currentRoute = .dashboard
    }
}
