import SwiftUI
import AuthenticationServices
import FirebaseAuth

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
    @Published var isAuthenticated: Bool = false
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
    
    // MARK: - OAuth Handlers
    func handleAppleSignInRequest(_ request: ASAuthorizationAppleIDRequest) {
        // Implement Apple nonce & scope request
        request.requestedScopes = [.fullName, .email]
    }
    
    func handleAppleSignInCompletion(_ result: Result<ASAuthorization, Error>) {
        // Implement Apple credential parsing and Firebase auth
        switch result {
        case .success(let authorization):
            print("Apple Sign-In Success: \(authorization)")
            isAuthenticated = true
        case .failure(let error):
            print("Apple Sign-In Failed: \(error.localizedDescription)")
        }
    }
    
    func signInWithGoogle() {
        // Implement Google SDK sign in
        print("Google Sign In clicked")
    }
    
    func uploadIdentityData(selectedOccasion: String) {
        guard let face = faceImage, let profile = profileImage, let body = bodyImage else { return }
        
        isUploadingToCloud = true
        uploadProgressText = "Verifying Secure Session..."
        
        Task { @MainActor in
            do {
                guard let userId = FirebaseAuth.Auth.auth().currentUser?.uid else {
                    throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated. Please log in."])
                }
                
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
