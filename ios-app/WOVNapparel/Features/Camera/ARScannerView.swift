import SwiftUI
import ARKit
import RealityKit

@available(iOS 14.0, *)
struct ARScannerView: View {
    @StateObject private var sizingEngine = LiDARSizingEngine()
    @State private var isProcessing = false
    @State private var matchResult: String? = nil
    
    var body: some View {
        ZStack {
            ARViewContainer(sizingEngine: sizingEngine)
                .ignoresSafeArea()
            
            // Framing Guide
            VStack {
                Spacer()
                Rectangle()
                    .stroke(Color.blue.opacity(0.8), style: StrokeStyle(lineWidth: 3, dash: [10]))
                    .frame(width: 300, height: 500)
                Spacer()
            }
            
            // UI Overlay
            VStack {
                HStack {
                    Spacer()
                    Text("LiDAR Active")
                        .font(.caption)
                        .padding(8)
                        .background(Color.green.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding()
                }
                Spacer()
                
                if isProcessing {
                    VStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                        Text("Extracting 3D Spatial Metrics...")
                            .foregroundColor(.white)
                            .padding(.top, 10)
                    }
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(16)
                    .padding(.bottom, 50)
                } else if let result = matchResult {
                    VStack {
                        Text("True LiDAR Measurement")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                        Text(result)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.green)
                            
                        Button("Scan Again") {
                            matchResult = nil
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
                        captureAndProcess()
                    }) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 70, height: 70)
                            .overlay(
                                Circle().stroke(Color.blue, lineWidth: 4)
                            )
                    }
                    .padding(.bottom, 50)
                }
            }
        }
        .preferredColorScheme(.light)
    }
    
    private func captureAndProcess() {
        guard let currentFrame = sizingEngine.activeSession?.currentFrame else { return }
        isProcessing = true
        
        Task {
            do {
                let metrics = try await sizingEngine.resolveUserSizing(userId: "demo_user", image: currentFrame.capturedImage)
                
                // Construct result text for demo purposes
                let chest = String(format: "%.1f cm", metrics["chestCm"] ?? 0)
                let waist = String(format: "%.1f cm", metrics["waistCm"] ?? 0)
                
                DispatchQueue.main.async {
                    self.matchResult = "Chest: \(chest)\nWaist: \(waist)"
                    self.isProcessing = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.matchResult = "Error: \(error.localizedDescription)"
                    self.isProcessing = false
                }
            }
        }
    }
}

@available(iOS 14.0, *)
struct ARViewContainer: UIViewRepresentable {
    @ObservedObject var sizingEngine: LiDARSizingEngine
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        let config = ARWorldTrackingConfiguration()
        
        // Enable LiDAR Scene Depth
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
            config.frameSemantics.insert(.sceneDepth)
        }
        
        arView.session.run(config)
        sizingEngine.activeSession = arView.session
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
}
