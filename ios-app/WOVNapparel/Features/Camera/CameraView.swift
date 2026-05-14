import SwiftUI

struct CameraView: View {
    @EnvironmentObject var appState: AppFlowState
    @AppStorage("userHeightInput") private var userHeightInput: String = ""
    
    @State private var technicalImage: UIImage? = nil
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let techImage = technicalImage {
                // Processing View
                VStack(spacing: 30) {
                    Text("Extracting Measurements")
                        .font(.system(size: 32, weight: .regular, design: .serif))
                        .foregroundColor(.white)
                        .padding(.top, 40)
                    
                    ZStack {
                        Image(uiImage: techImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 500)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        if isProcessing {
                            Rectangle()
                                .fill(LinearGradient(gradient: Gradient(colors: [.clear, .green.opacity(0.8), .clear]), startPoint: .top, endPoint: .bottom))
                                .frame(height: 20)
                                .offset(y: scanLineOffset)
                                .animation(Animation.linear(duration: 1.5).repeatForever(autoreverses: true), value: scanLineOffset)
                                .onAppear { scanLineOffset = 250 }
                        }
                    }
                    
                    VStack(spacing: 12) {
                        ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white)).scaleEffect(1.2)
                        Text(processText)
                            .font(.system(size: 14, weight: .semibold))
                            .tracking(1.5)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                }
            } else {
                // Live Camera View
                ImagePicker(selectedImage: $technicalImage, sourceType: .camera)
                    .ignoresSafeArea()
                
                // Silhouette Overlay
                VStack {
                    Spacer()
                    Image(systemName: "figure.stand")
                        .resizable()
                        .scaledToFit()
                        .frame(height: UIScreen.main.bounds.height * 0.6)
                        .foregroundColor(Color.green.opacity(0.4))
                        .shadow(color: .green, radius: 10)
                    Spacer()
                }
                .allowsHitTesting(false) // Let touches pass through to the camera
                
                // Header Instructions
                VStack {
                    HStack {
                        Button(action: {
                            appState.currentRoute = .onboardingPhotos
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                                .padding()
                        }
                        Spacer()
                    }
                    
                    Text("TECHNICAL MEASUREMENT")
                        .font(.system(size: 14, weight: .bold))
                        .tracking(2)
                        .foregroundColor(.white)
                        .padding(.top, -40)
                    
                    Text("Stand perfectly inside the green silhouette.")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                    
                    Spacer()
                }
            }
        }
        .preferredColorScheme(.dark)
        .onChange(of: technicalImage) { newImage in
            if newImage != nil {
                processPseudo3DScan()
            }
        }
    }
    
    private func processPseudo3DScan() {
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            
            DispatchQueue.main.async { self.processText = "Extrapolating Z-Axis Depth..." }
            
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            
            if let image = technicalImage?.cgImage {
                let parsedHeight = Double(userHeightInput.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) ?? 170.0
                
                do {
                    // Extract exact measurements from this specific technical photo
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
                withAnimation { appState.currentRoute = .profileReview }
            }
        }
    }
}
