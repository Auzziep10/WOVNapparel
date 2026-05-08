import SwiftUI

struct CameraView: View {
    @StateObject private var cameraManager = CameraManager()
    @State private var isProcessing = false
    @State private var matchResult: String? = nil
    
    // Core logic engine
    private let sizingEngine = SpatialSizingEngine()
    
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
                        
                        Button("Retake") {
                            matchResult = nil
                            cameraManager.capturedImage = nil
                        }
                        .padding(.top, 10)
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
                // 1. Run local spatial sizing math
                let userMetrics = try await sizingEngine.resolveUserSizing(userId: "demo_user", actualHeightCm: 180.0, image: image)
                
                // 2. Fetch Match from Vercel Backend
                try await fetchVercelMatch(metrics: userMetrics)
                
            } catch {
                print("Sizing Error: \(error)")
                DispatchQueue.main.async {
                    self.matchResult = "Error"
                    self.isProcessing = false
                }
            }
        }
    }
    
    private func fetchVercelMatch(metrics: [String: Double]) async throws {
        // Build payload
        let payload: [String: Any] = [
            "techPackId": "demo_tech_pack", // In a real app, user selects a garment first
            "userMetrics": [
                "chestCm": metrics["chestCm"] ?? 100.0,
                "waistCm": metrics["waistCm"] ?? 85.0,
                "hipsCm": metrics["hipsCm"] ?? 95.0,
                "chromaticContrastIndex": 40.0
            ]
        ]
        
        guard let url = URL(string: "https://wovn-apparel.vercel.app/api/match") else { return }
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
                self.matchResult = "Size M" // Fallback if tech pack ID is missing
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
