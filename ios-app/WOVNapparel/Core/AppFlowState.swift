import SwiftUI
import AuthenticationServices
import FirebaseAuth
import FirebaseCore
import CryptoKit
import GoogleSignIn

// Utility function to generate a random nonce
private func randomNonceString(length: Int = 32) -> String {
    precondition(length > 0)
    var randomBytes = [UInt8](repeating: 0, count: length)
    let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
    if errorCode != errSecSuccess {
        fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
    }
    
    let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    let nonce = randomBytes.map { byte in
        charset[Int(byte) % charset.count]
    }
    
    return String(nonce)
}

private func sha256(_ input: String) -> String {
    let inputData = Data(input.utf8)
    let hashedData = SHA256.hash(data: inputData)
    let hashString = hashedData.compactMap {
        String(format: "%02x", $0)
    }.joined()
    
    return hashString
}

struct Garment: Identifiable, Codable, Equatable {
    let id: String
    let type: String
    let thumbnail: String
    
    var baseId: String {
        if let range = id.range(of: "_cw_") {
            return String(id[..<range.lowerBound])
        }
        return id
    }
}

struct SavedRender: Identifiable, Equatable {
    let id: String
    let url: String
    let garmentId: String
    let occasion: String
}

enum AppRoute: Equatable {
    case loading
    case onboardingBasic
    case onboardingPhotos
    case lidarCaptureFlow
    case standardCaptureFlow
    case profileReview
    case occasionSelection
    case tryOn(techPackId: String)
    case gallery
    case tryOnDetail(render: SavedRender)
}

class AppFlowState: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var currentRoute: AppRoute = .loading
    
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
    
    // Remote Data State
    @Published var savedTryOns: [SavedRender] = []
    @Published var remoteFaceURL: String? = nil
    @Published var remoteProfileURL: String? = nil
    @Published var remoteBodyURL: String? = nil
    
    // Mock Session ID for Demo Purposes when Firebase Auth is missing
    @Published var mockSessionId: String = UUID().uuidString
    
    // OAuth Nonce
    @Published var currentNonce: String?
    
    init() {
        // Listen for authentication state changes automatically on app launch
        FirebaseAuth.Auth.auth().addStateDidChangeListener { [weak self] auth, user in
            guard let self = self else { return }
            
            if let user = user {
                self.isAuthenticated = true
                self.currentRoute = .loading
                self.fetchUserData(userId: user.uid)
            } else {
                self.isAuthenticated = false
                self.currentRoute = .onboardingBasic
            }
        }
    }
    
    func fetchUserData(userId: String) {
        Task { @MainActor in
            do {
                let (measurements, photos) = try await FirebaseManager.shared.fetchUserProfile(userId: userId)
                
                let tryOns = try await FirebaseManager.shared.fetchUserRenders(userId: userId)
                self.savedTryOns = tryOns
                
                let hasMeasurements = !(measurements?.isEmpty ?? true)
                let hasPhotos = !(photos?.isEmpty ?? true)
                
                // If they have BOTH photos and measurements, they've completed onboarding
                if hasMeasurements && hasPhotos {
                    self.hasProfile = true
                    if let measurements = measurements { self.userMetrics = measurements }
                    if let photos = photos {
                        self.remoteFaceURL = photos["face"]
                        self.remoteProfileURL = photos["profile"]
                        self.remoteBodyURL = photos["body"]
                    }
                    self.currentRoute = .profileReview
                } else {
                    // Missing either photos or measurements, push them to onboarding!
                    self.hasProfile = false
                    self.currentRoute = .onboardingBasic
                }
            } catch {
                print("Failed to fetch user data: \(error)")
                self.hasProfile = false
                self.currentRoute = .onboardingBasic
            }
        }
    }
    
    func loadGarments(for occasion: String) {
        Task { @MainActor in
            do {
                // Extract skin LAB if available
                var userSkinLAB: [Double]? = nil
                if let l = self.userMetrics["skinL"], let a = self.userMetrics["skinA"], let b = self.userMetrics["skinB"] {
                    userSkinLAB = [l, a, b]
                }
                
                let fetched = try await FirebaseManager.shared.fetchGarments(for: occasion, skinLAB: userSkinLAB)
                if fetched.isEmpty {
                    // Fallback to mock garments if the database is completely empty for this occasion
                    self.recommendedGarments = [
                        Garment(id: "g_shirt_1", type: "top", thumbnail: "https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=200&h=200&fit=crop"),
                        Garment(id: "g_pant_1", type: "bottom", thumbnail: "https://images.unsplash.com/photo-1584865288642-42078afe6942?w=200&h=200&fit=crop")
                    ]
                } else {
                    self.recommendedGarments = fetched
                }
            } catch {
                print("Failed to fetch garments: \(error)")
                self.recommendedGarments = [
                    Garment(id: "g_shirt_1", type: "top", thumbnail: "https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=200&h=200&fit=crop")
                ]
            }
        }
    }
    
    func completeOnboarding() {
        hasProfile = true
        currentRoute = .profileReview
    }
    
    func updateMetricsDirectly(_ newMetrics: [String: Double]) {
        self.userMetrics = newMetrics
        
        Task { @MainActor in
            do {
                let userId = FirebaseAuth.Auth.auth().currentUser?.uid ?? mockSessionId
                
                var urls: [String: String] = [:]
                if let body = remoteBodyURL { urls["body"] = body }
                if let face = remoteFaceURL { urls["face"] = face }
                if let profile = remoteProfileURL { urls["profile"] = profile }
                
                try await FirebaseManager.shared.saveMetrics(newMetrics, userId: userId, photoURLs: urls)
                print("Successfully updated metrics in Firestore directly.")
            } catch {
                print("Failed to save updated metrics: \(error)")
            }
        }
    }
    
    func handleAppleSignInRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonceString()
        self.currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
    }
    
    func handleAppleSignInCompletion(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                guard let nonce = currentNonce else {
                    print("Invalid state: A login callback was received, but no login request was sent.")
                    return
                }
                guard let appleIDToken = appleIDCredential.identityToken else {
                    print("Unable to fetch identity token")
                    return
                }
                guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                    print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                    return
                }
                
                let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: idTokenString, rawNonce: nonce)
                
                Task {
                    do {
                        let authResult = try await Auth.auth().signIn(with: credential)
                        DispatchQueue.main.async {
                            self.isAuthenticated = true
                            self.fetchUserData(userId: authResult.user.uid)
                        }
                    } catch {
                        print("Error authenticating: \(error.localizedDescription)")
                    }
                }
            }
        case .failure(let error):
            print("Apple Sign-In Failed: \(error.localizedDescription)")
        }
    }
    
    func signInWithGoogle() {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            return
        }
        
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [weak self] result, error in
            guard let self = self else { return }
            guard error == nil else {
                print("Google Sign In Error: \(error?.localizedDescription ?? "Unknown")")
                return
            }
            
            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                return
            }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                           accessToken: user.accessToken.tokenString)
            Task {
                do {
                    let authResult = try await Auth.auth().signIn(with: credential)
                    DispatchQueue.main.async {
                        self.isAuthenticated = true
                        self.fetchUserData(userId: authResult.user.uid)
                    }
                } catch {
                    print("Firebase Google Auth Error: \(error.localizedDescription)")
                }
            }
        }
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
    
    func fetchSizeRecommendation(techPackId: String) async throws -> String {
        // Fallback or demo case
        if techPackId == "DEFAULT" || techPackId.isEmpty {
            return "Recommended Size: M"
        }
        
        let url = URL(string: "https://wovn-apparel-companion.vercel.app/api/match")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: Any] = [
            "techPackId": techPackId,
            "userMetrics": [
                "chestCm": userMetrics["chestCm"] ?? (userMetrics["chest"] ?? 0) * 2.54,
                "waistCm": userMetrics["waistCm"] ?? (userMetrics["waist"] ?? 0) * 2.54,
                "hipsCm": userMetrics["hipsCm"] ?? (userMetrics["hips"] ?? 0) * 2.54,
                "chromaticContrastIndex": 50 // arbitrary default
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResp = response as? HTTPURLResponse, httpResp.statusCode == 200 else {
            print("API Match failed with status \((response as? HTTPURLResponse)?.statusCode ?? 500)")
            return "Size: Unknown"
        }
        
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let success = json["success"] as? Bool, success,
           let responseData = json["data"] as? [String: Any],
           let recommendedSize = responseData["recommendedSize"] as? String {
            return "Recommended Size: \(recommendedSize)"
        }
        
        return "Size: Unknown"
    }
    
    func uploadIdentityData(selectedOccasion: String) {
        guard let body = bodyImage else { 
            print("Notice: Missing body photo. Skipping cloud upload and jumping to Try-On for demo purposes.")
            self.loadGarments(for: selectedOccasion)
            self.currentRoute = .tryOn(techPackId: selectedOccasion)
            return 
        }
        
        isUploadingToCloud = true
        uploadProgressText = "Verifying Secure Session..."
        
        Task { @MainActor in
            do {
                let userId = FirebaseAuth.Auth.auth().currentUser?.uid ?? mockSessionId
                
                if let face = faceImage {
                    self.uploadProgressText = "Analyzing Chromatic Profile..."
                    let contrastIndex = await ChromaticAnalyzer.analyzeContrast(image: face)
                    self.userMetrics["chromaticContrastIndex"] = contrastIndex
                    
                    if let skinLab = try? await SpectrophotometricSkinAnalyzer().extractSkinChromaticProfile(from: face) {
                        self.userMetrics["skinL"] = Double(skinLab[0])
                        self.userMetrics["skinA"] = Double(skinLab[1])
                        self.userMetrics["skinB"] = Double(skinLab[2])
                        print("Extracted User CIELAB Skin Profile: L: \(skinLab[0]), a: \(skinLab[1]), b: \(skinLab[2])")
                    }
                }
                
                self.uploadProgressText = "Encrypting & Syncing Photos..."
                
                var fURL: URL? = nil
                var pURL: URL? = nil
                
                if let face = faceImage { fURL = try await FirebaseManager.shared.uploadImage(face, path: "users/\(userId)/identity/face.jpg") }
                if let profile = profileImage { pURL = try await FirebaseManager.shared.uploadImage(profile, path: "users/\(userId)/identity/profile.jpg") }
                let bURL = try await FirebaseManager.shared.uploadImage(body, path: "users/\(userId)/identity/body.jpg")
                
                var urls: [String: String] = ["body": bURL.absoluteString]
                if let f = fURL { urls["face"] = f.absoluteString }
                if let p = pURL { urls["profile"] = p.absoluteString }
                
                self.uploadProgressText = "Locking In Spatial Metrics..."
                
                try await FirebaseManager.shared.saveMetrics(self.userMetrics, userId: userId, photoURLs: urls)
                
                self.uploadProgressText = "Identity Synced Successfully."
                try await Task.sleep(nanoseconds: 1_000_000_000)
                
                self.isUploadingToCloud = false
                self.loadGarments(for: selectedOccasion)
                self.currentRoute = .tryOn(techPackId: selectedOccasion)
                
            } catch {
                print("Failed to sync identity: \(error)")
                self.uploadProgressText = "Sync Failed. Proceeding locally..."
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                self.isUploadingToCloud = false
                self.loadGarments(for: selectedOccasion)
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
        
        // Simulate progress for AI generation with realistic deceleration curve
        let progressTask = Task { @MainActor in
            var i = 1
            while i < 99 {
                if Task.isCancelled { break }
                synthesisProgress = i
                
                let sleepNs: UInt64
                if i < 40 {
                    sleepNs = 60_000_000   // 60ms
                } else if i < 70 {
                    sleepNs = 120_000_000  // 120ms
                } else if i < 85 {
                    sleepNs = 250_000_000  // 250ms
                } else if i < 95 {
                    sleepNs = 500_000_000  // 500ms
                } else {
                    sleepNs = 1_000_000_000 // 1s
                }
                
                try? await Task.sleep(nanoseconds: sleepNs)
                i += 1
            }
        }
        
        Task { @MainActor in
            do {
                let gIdSafe = garmentId ?? "DEFAULT"
                
                var token = ""
                if let currentUser = FirebaseAuth.Auth.auth().currentUser {
                    token = try await currentUser.getIDToken()
                }
                
                let endpoint = "https://wovn-apparel-companion.vercel.app/api/render-fit"
                guard let url = URL(string: endpoint) else {
                    self.isSynthesizing = false
                    return
                }
                
                let payload: [String: Any] = [
                    "userId": userId,
                    "occasion": occasion,
                    "garmentId": gIdSafe
                ]
                
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                if !token.isEmpty {
                    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                }
                request.httpBody = try JSONSerialization.data(withJSONObject: payload)
                
                let (data, response) = try await URLSession.shared.data(for: request)
                progressTask.cancel() // Stop simulated progress
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    self.isSynthesizing = false
                    return
                }
                
                if httpResponse.statusCode == 429 {
                    print("Stylist Error: Rate Limit Reached (429)")
                    self.isSynthesizing = false
                    return
                }
                
                if httpResponse.statusCode != 200 {
                    let errStr = String(data: data, encoding: .utf8) ?? "Unknown Error"
                    print("Stylist Error: Backend API failed. Status: \(httpResponse.statusCode). Msg: \(errStr)")
                    self.isSynthesizing = false
                    return
                }
                
                guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let success = json["success"] as? Bool, success,
                      let renderUrlString = json["mockRenderUrl"] as? String,
                      let renderUrl = URL(string: renderUrlString) else {
                    print("Stylist Error: Could not parse response JSON or mockRenderUrl missing")
                    self.isSynthesizing = false
                    return
                }
                
                synthesisProgress = 100 // Snap to 100%
                try await Task.sleep(nanoseconds: 300_000_000)
                
                print("Stylist: Backend synthesis successful! URL: \(renderUrlString)")
                self.generatedImageURL = renderUrl
                self.renderCache[cacheKey] = renderUrl // Save to intelligent cache
                
                // Add to local list to update gallery
                let newRender = SavedRender(
                    id: UUID().uuidString,
                    url: renderUrlString,
                    garmentId: gIdSafe,
                    occasion: occasion
                )
                self.savedTryOns.insert(newRender, at: 0)
                
                self.isSynthesizing = false
            } catch {
                print("Failed to trigger backend synthesis: \(error)")
                progressTask.cancel()
                self.isSynthesizing = false
            }
        }
    }
}

extension UIImage {
    func resizeAndGetBase64() -> String? {
        let maxDimension: CGFloat = 1024.0
        var newSize = self.size
        
        if size.width > maxDimension || size.height > maxDimension {
            let ratio = maxDimension / max(size.width, size.height)
            newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        }
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        self.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let finalImage = resizedImage,
              let imageData = finalImage.jpegData(compressionQuality: 0.7) else { return nil }
        
        return imageData.base64EncodedString()
    }
}
