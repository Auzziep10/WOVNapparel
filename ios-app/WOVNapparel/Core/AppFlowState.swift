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
    
    // Cloud Sync State
    @Published var isUploadingToCloud: Bool = false
    @Published var uploadProgressText: String = ""
    
    func completeOnboarding() {
        hasProfile = true
        currentRoute = .profileReview
    }
    
    func uploadIdentityData(selectedOccasion: String) {
        guard let face = faceImage, let profile = profileImage, let body = bodyImage else { return }
        
        isUploadingToCloud = true
        uploadProgressText = "Authenticating Secure Session..."
        
        Task { @MainActor in
            do {
                let userId = try await FirebaseManager.shared.authenticateAnonymously()
                
                self.uploadProgressText = "Encrypting & Syncing Photos..."
                
                // Upload images concurrently
                async let faceURL = FirebaseManager.shared.uploadImage(face, path: "users/\(userId)/identity/face.jpg")
                async let profileURL = FirebaseManager.shared.uploadImage(profile, path: "users/\(userId)/identity/profile.jpg")
                async let bodyURL = FirebaseManager.shared.uploadImage(body, path: "users/\(userId)/identity/body.jpg")
                
                let (fURL, pURL, bURL) = try await (faceURL, profileURL, bodyURL)
                
                let urls = [
                    "face": fURL.absoluteString,
                    "profile": pURL.absoluteString,
                    "body": bURL.absoluteString
                ]
                
                self.uploadProgressText = "Locking In Spatial Metrics..."
                
                try await FirebaseManager.shared.saveMetrics(self.userMetrics, userId: userId, photoURLs: urls)
                
                // Add a slight delay so the user can read the success state
                self.uploadProgressText = "Identity Synced Successfully."
                try await Task.sleep(nanoseconds: 1_000_000_000)
                
                self.isUploadingToCloud = false
                self.currentRoute = .tryOn(techPackId: "mock_\(selectedOccasion)")
                
            } catch {
                print("Failed to sync identity: \(error)")
                self.uploadProgressText = "Sync Failed. Retrying..."
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                self.isUploadingToCloud = false
            }
        }
    }
}
