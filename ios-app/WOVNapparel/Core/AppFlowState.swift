import SwiftUI

enum AppRoute: Equatable {
    case onboardingBasic
    case onboardingPhotos
    case lidarCaptureFlow
    case standardCaptureFlow
    case profileReview
    case occasionSelection
    case tryOn(techPackId: String)
}

class AppFlowState: ObservableObject {
    @Published var currentRoute: AppRoute = .onboardingBasic
    
    // We will sync this with Firestore shortly
    @Published var hasProfile: Bool = false
    @Published var userName: String = ""
    @Published var userMetrics: [String: Double] = [:]
    
    // Captured Identity Data
    @Published var faceImage: UIImage? = nil
    @Published var profileImage: UIImage? = nil
    @Published var bodyImage: UIImage? = nil
    @Published var scannedModelURL: URL? = nil
    
    func completeOnboarding() {
        hasProfile = true
        currentRoute = .profileReview
    }
}
