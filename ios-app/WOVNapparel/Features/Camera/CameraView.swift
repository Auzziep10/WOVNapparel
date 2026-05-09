import SwiftUI
import AVFoundation
import Vision
import FirebaseFirestore

struct CameraView: View {
    @StateObject private var cameraManager = CameraManager()
    @State private var isProcessing = false
    @State private var matchResult: String? = nil
    @State private var skinToneColor: Color? = nil
    
    // Core logic engines
    private let sizingEngine = SpatialSizingEngine()
    private let colorAnalyzer = SpectrophotometricSkinAnalyzer()
    
    var body: some View {
        ZStack {
            if cameraManager.isCameraSetup {
                CameraPreview(cameraManager: cameraManager)
                    .ignoresSafeArea()
                
                // Framing Guide
                VStack {
                    Spacer()
                    Rectangle()
                        .stroke(Color.white.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [10]))
                        .frame(width: 300, height: 400)
                    Spacer()
                }
            } else {
                Color.black.ignoresSafeArea()
                ProgressView("Initializing Camera...")
                    .foregroundColor(.white)
            }
            
            // UI Overlay
            VStack {
                Spacer()
                
                if isProcessing {
                    VStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                        Text("Running Spatial Decimation...")
                            .foregroundColor(.white)
                            .padding(.top, 10)
                    }
                    .padding(.bottom, 50)
                } else if let result = matchResult {
                    VStack {
                        Text("Recommended Match")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.8))
                        Text(result)
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.green)
                            
                        if let skinColor = skinToneColor {
                            HStack {
                                Circle()
                                    .fill(skinColor)
                                    .frame(width: 30, height: 30)
                                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                Text("High Contrast Winter")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            .padding(.top, 5)
                        }
                        
                        Button("Retake") {
                            matchResult = nil
                            skinToneColor = nil
                            cameraManager.capturedImage = nil
                        }
                        .padding(.top, 15)
                        .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(20)
                    .padding(.bottom, 50)
                } else {
                    Button(action: {
                        cameraManager.capturePhoto()
                    }) {
                        Circle()
                            .stroke(Color.white, lineWidth: 4)
                            .frame(width: 70, height: 70)
                            .overlay(
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 60, height: 60)
                            )
                    }
                    .padding(.bottom, 50)
                }
            }
        }
        .onChange(of: cameraManager.capturedImage) { image in
            if let image = image {
                processImage(image)
            }
        }
    }
    
    private func processImage(_ image: CGImage) {
        isProcessing = true
        
        Task {
            do {
                let uiImage = UIImage(cgImage: image)
                
                // 1. Run local spatial sizing & color math CONCURRENTLY
                async let sizingTask = sizingEngine.resolveUserSizing(userId: "demo_user", actualHeightCm: 180.0, image: image)
                async let colorTask = colorAnalyzer.extractSkinChromaticProfile(from: uiImage)
                
                let (userMetrics, labProfile) = try await (sizingTask, colorTask)
                
                DispatchQueue.main.async {
                    if let lab = labProfile, lab.count >= 3 {
                        // Very rough mock LAB -> RGB for visual UI scaffold
                        let l = Double(lab[0]) / 100.0
                        self.skinToneColor = Color(red: l + 0.1, green: l - 0.1, blue: l - 0.2) 
                    }
                }
                
                // 2. Fetch Match from Vercel Backend
                try await fetchVercelMatch(metrics: userMetrics, skinToneLab: labProfile)
                
            } catch {
                print("Sizing Error: \(error)")
                DispatchQueue.main.async {
                    self.matchResult = "Error"
                    self.isProcessing = false
                }
            }
        }
    }
    
    private func fetchVercelMatch(metrics: [String: Double], skinToneLab: [Float]?) async throws {
        // INJECT DEMO TECH PACK INTO FIRESTORE (Fix for 19h-old Vercel Code)
        let db = Firestore.firestore()
        try? await db.collection("tech_packs").document("demo_tech_pack").setData([
            "name": "WOVN Heavyweight Core Hoodie",
            "baseSize": "M",
            "measurements": ["bustCm": 105, "waistCm": 95, "hemCm": 92],
            "fabricProperties": ["stretchCoefficient": 1.1],
            "dominantColorways": [["name": "Onyx Black", "lab": [15, 0, 0]]]
        ])
        
        // Build payload
        var payload: [String: Any] = [
            "techPackId": "demo_tech_pack", // In a real app, user selects a garment first
            "userMetrics": [
                "chestCm": metrics["chestCm"] ?? 100.0,
                "waistCm": metrics["waistCm"] ?? 85.0,
                "hipsCm": metrics["hipsCm"] ?? 95.0,
                "chromaticContrastIndex": 40.0
            ]
        ]
        
        if let lab = skinToneLab {
            payload["userSkinToneLab"] = lab
        }
        
        // Point to the Next.js server running locally on the Mac
        guard let url = URL(string: "http://192.168.4.94:3000/api/match") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(MatchResponse.self, from: data)
        
        DispatchQueue.main.async {
            if response.success, let matchData = response.data {
                self.matchResult = "Size \(matchData.recommendedSize)"
            } else {
                self.matchResult = "Error"
            }
            self.isProcessing = false
        }
    }
}

// API Response Models
struct MatchResponse: Codable {
    let success: Bool
    let data: MatchData?
}

struct MatchData: Codable {
    let recommendedSize: String
    let confidenceScore: Int
    let recommendedColorway: String
}
