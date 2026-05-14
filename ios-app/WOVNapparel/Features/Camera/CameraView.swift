import SwiftUI

struct CameraView: View {
    @EnvironmentObject var appState: AppFlowState
    @AppStorage("userHeightInput") private var userHeightInput: String = ""
    
    @State private var isProcessing = true
    @State private var scanLineOffset: CGFloat = -200
    @State private var processText = "Analyzing Spatial Proportions..."
    
    private let sizingEngine = SpatialSizingEngine()
    
    var body: some View {
        ZStack {
            // Minimalist Garment Catalog Background
            Color(red: 244/255, green: 244/255, blue: 245/255).ignoresSafeArea()
            
            VStack(spacing: 30) {
                Text("Pseudo-3D Synthesis")
                    .font(.system(size: 32, weight: .regular, design: .serif))
                    .foregroundColor(Color(red: 24/255, green: 24/255, blue: 27/255))
                    .padding(.top, 40)
                
                // Display the captured full body photo with a scanning effect
                if let bodyImage = appState.bodyImage {
                    ZStack {
                        Image(uiImage: bodyImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 400)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
                        
                        if isProcessing {
                            // Holographic Scan Line
                            Rectangle()
                                .fill(LinearGradient(gradient: Gradient(colors: [.clear, .green.opacity(0.8), .clear]), startPoint: .top, endPoint: .bottom))
                                .frame(height: 20)
                                .offset(y: scanLineOffset)
                                .animation(Animation.linear(duration: 1.5).repeatForever(autoreverses: true), value: scanLineOffset)
                                .onAppear {
                                    scanLineOffset = 200
                                }
                        }
                    }
                    .frame(maxHeight: 400)
                } else {
                    Rectangle()
                        .fill(Color(white: 0.9))
                        .frame(width: 250, height: 400)
                        .overlay(Text("No Body Photo Found").foregroundColor(.gray))
                }
                
                VStack(spacing: 12) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                        .scaleEffect(1.2)
                    
                    Text(processText)
                        .font(.system(size: 14, weight: .semibold))
                        .tracking(1.5)
                        .foregroundColor(Color(red: 113/255, green: 113/255, blue: 122/255))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.top, 20)
                
                Spacer()
            }
        }
        .preferredColorScheme(.light)
        .onAppear {
            processPseudo3DScan()
        }
    }
    
    private func processPseudo3DScan() {
        Task {
            // Simulate deep spatial analysis
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            
            DispatchQueue.main.async {
                self.processText = "Extrapolating Z-Axis Depth..."
            }
            
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            
            // Actually call the sizing engine if an image is available
            if let image = appState.bodyImage?.cgImage {
                let parsedHeight = Double(userHeightInput.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) ?? 170.0
                
                // Fire and forget - stores metrics natively
                do {
                    appState.userMetrics = try await sizingEngine.resolveUserSizing(userId: "current_user", actualHeightCm: parsedHeight, image: image)
                } catch {
                    print("Sizing engine failed: \(error)")
                }
            }
            
            DispatchQueue.main.async {
                self.processText = "Synthesis Complete."
                self.isProcessing = false
            }
            
            try? await Task.sleep(nanoseconds: 800_000_000)
            
            DispatchQueue.main.async {
                withAnimation {
                    // Route to Profile Dashboard for final review!
                    appState.currentRoute = .profileReview
                }
            }
        }
    }
}
