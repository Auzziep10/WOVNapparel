import SwiftUI

enum AppRoute: Equatable {
    case onboardingBasic
    case onboardingPhotos
    case dashboard
    case lidarCaptureFlow
    case standardCaptureFlow
    case tryOn(techPackId: String)
}

class AppFlowState: ObservableObject {
    @Published var currentRoute: AppRoute = .onboardingBasic
    
    // We will sync this with Firestore shortly
    @Published var hasProfile: Bool = false
    @Published var userName: String = ""
    @Published var userMetrics: [String: Double] = [:]
    
    func completeOnboarding() {
        hasProfile = true
        currentRoute = .dashboard
    }
}
