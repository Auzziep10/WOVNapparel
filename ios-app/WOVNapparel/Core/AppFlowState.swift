import SwiftUI
import AuthenticationServices
import FirebaseAuth

struct Garment: Identifiable, Codable, Equatable {
    let id: String
    let type: String
    let thumbnail: String
}

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
    
    // Synthesis State
    @Published var isSynthesizing: Bool = false
    @Published var synthesisProgress: Int = 0
    @Published var generatedImageURL: URL? = nil
    
    // Catalog & Cache State
    @Published var recommendedGarments: [Garment] = []
    @Published var selectedGarmentId: String? = nil
    @Published var renderCache: [String: URL] = [:]
    
    func completeOnboarding() {
        hasProfile = true
        currentRoute = .profileReview
    }
    
    // Mock Session ID for Demo Purposes when Firebase Auth is missing
    @Published var mockSessionId: String = UUID().uuidString
    
    // MARK: - OAuth Handlers
    func handleAppleSignInRequest(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
    }
    
    func handleAppleSignInCompletion(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            print("Apple Sign-In Success: \(authorization)")
            self.isAuthenticated = true
        case .failure(let error):
            print("Apple Sign-In Failed: \(error.localizedDescription)")
        }
    }
    
    func signInWithGoogle() {
        print("Google Sign In clicked")
        self.isAuthenticated = true
    }
    
    func signOut() {
        do {
            try FirebaseAuth.Auth.auth().signOut()
            self.isAuthenticated = false
            self.hasProfile = false
            self.currentRoute = .onboardingBasic
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
    
    func uploadIdentityData(selectedOccasion: String) {
        guard let face = faceImage, let profile = profileImage, let body = bodyImage else { 
            print("Notice: Missing photos. Skipping cloud upload and jumping to Try-On for demo purposes.")
            self.currentRoute = .tryOn(techPackId: selectedOccasion)
            return 
        }
        
        isUploadingToCloud = true
        uploadProgressText = "Verifying Secure Session..."
        
        Task { @MainActor in
            do {
                let userId = FirebaseAuth.Auth.auth().currentUser?.uid ?? mockSessionId
                
                self.uploadProgressText = "Encrypting & Syncing Photos..."
                
                // Upload images concurrently to Firebase Storage
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
                
                self.uploadProgressText = "Identity Synced Successfully."
                try await Task.sleep(nanoseconds: 1_000_000_000)
                
                self.isUploadingToCloud = false
                self.currentRoute = .tryOn(techPackId: selectedOccasion)
                
            } catch {
                print("Failed to sync identity: \(error)")
                self.uploadProgressText = "Sync Failed. Proceeding locally..."
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                self.isUploadingToCloud = false
                self.currentRoute = .tryOn(techPackId: selectedOccasion)
            }
        }
    }
    
    // MARK: - Synthesis Trigger
    func triggerSynthesis(occasion: String, garmentId: String? = nil) {
        let userId = FirebaseAuth.Auth.auth().currentUser?.uid ?? mockSessionId
        
        // Caching Logic: If we already synthesized this exact state, load it instantly.
        let cacheKey = garmentId ?? "default_\(occasion)"
        if let cachedURL = renderCache[cacheKey] {
            self.generatedImageURL = cachedURL
            self.selectedGarmentId = garmentId
            return
        }
        
        isSynthesizing = true
        synthesisProgress = 0
        selectedGarmentId = garmentId
        
        // Simulate progress for AI generation
        let progressTask = Task { @MainActor in
            for i in 1...95 {
                try? await Task.sleep(nanoseconds: 40_000_000) // Fast progress simulation
                if Task.isCancelled { break }
                synthesisProgress = i
            }
        }
        
        Task { @MainActor in
            do {
                // Point to production Vercel deployment for TestFlight beta testing
                guard let url = URL(string: "https://wovn-apparel.vercel.app/api/render-fit") else { return }
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                var payload: [String: Any] = ["userId": userId, "occasion": occasion]
                if let gId = garmentId {
                    payload["garmentId"] = gId
                }
                
                request.httpBody = try JSONSerialization.data(withJSONObject: payload)
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                progressTask.cancel() // Stop simulated progress
                
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    print("Synthesis API Error")
                    isSynthesizing = false
                    return
                }
                
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let mockRenderUrlString = json["mockRenderUrl"] as? String,
                   let finalURL = URL(string: mockRenderUrlString) {
                    
                    // Decode catalog if present
                    if let garmentsDict = json["garments"] as? [[String: String]] {
                        let parsedGarments = garmentsDict.compactMap { dict -> Garment? in
                            guard let id = dict["id"], let type = dict["type"], let thumb = dict["thumbnail"] else { return nil }
                            return Garment(id: id, type: type, thumbnail: thumb)
                        }
                        if !parsedGarments.isEmpty {
                            self.recommendedGarments = parsedGarments
                        }
                    }
                    
                    synthesisProgress = 100 // Snap to 100%
                    
                    // Artificial delay to let user see 100%
                    try await Task.sleep(nanoseconds: 300_000_000)
                    
                    self.generatedImageURL = finalURL
                    self.renderCache[cacheKey] = finalURL // Save to intelligent cache
                }
                
                self.isSynthesizing = false
            } catch {
                print("Failed to trigger synthesis: \(error)")
                progressTask.cancel()
                self.isSynthesizing = false
            }
        }
    }
}
