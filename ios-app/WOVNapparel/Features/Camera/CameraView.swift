import SwiftUI

struct CameraView: View {
    @EnvironmentObject var appState: AppFlowState
    @AppStorage("userHeightInput") private var userHeightInput: String = ""
    
    @State private var technicalImage: UIImage? = nil
    @State private var isProcessing = true
    @State private var scanLineOffset: CGFloat = -200
    @State private var processText = "Analyzing Spatial Proportions..."
    
    // Vision AR Tracking State
    @State private var boundingBox: CGRect = .zero
    @State private var joints: [CGPoint] = []
    @State private var lines: [SkeletalLine] = []
    @State private var isBodyFullyVisible: Bool = false
    @State private var shouldCapture: Bool = false
    @State private var shouldFlipCamera: Bool = false
    @State private var countdown: Int = 2
    @State private var timer: Timer? = nil
    
    private let sizingEngine = SpatialSizingEngine()
    
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
                // Live AR Camera View
                VisionCaptureView(isBodyFullyVisible: $isBodyFullyVisible, boundingBox: $boundingBox, joints: $joints, lines: $lines, capturedImage: $technicalImage, shouldCapture: $shouldCapture, shouldFlipCamera: $shouldFlipCamera)
                    .ignoresSafeArea()
                
                // Dynamic AR Skeleton Overlay
                ZStack {
                    // Bones
                    ForEach(lines) { line in
                        Path { path in
                            path.move(to: line.start)
                            path.addLine(to: line.end)
                        }
                        .stroke(isBodyFullyVisible ? Color.green : Color.yellow, style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))
                        .shadow(color: isBodyFullyVisible ? Color.green : Color.yellow, radius: 8)
                        .animation(.interactiveSpring(), value: line)
                    }
                    
                    // Joint Nodes
                    ForEach(0..<joints.count, id: \.self) { i in
                        Circle()
                            .fill(Color.white)
                            .frame(width: 14, height: 14)
                            .position(joints[i])
                            .shadow(color: .black, radius: 2)
                            .animation(.interactiveSpring(), value: joints[i])
                    }
                }
                .allowsHitTesting(false)
                
                // Countdown Overlay
                if isBodyFullyVisible && countdown <= 2 && timer != nil {
                    Text("\(countdown)")
                        .font(.system(size: 140, weight: .bold))
                        .foregroundColor(.green)
                        .shadow(color: .black, radius: 10)
                }
                
                // Header Instructions & Controls
                VStack {
                    VStack(spacing: 4) {
                        Text(isBodyFullyVisible ? "PERFECT POSITION" : "TECHNICAL MEASUREMENT")
                            .font(.system(size: 14, weight: .bold))
                            .tracking(2)
                            .foregroundColor(isBodyFullyVisible ? .green : .white)
                        
                        Text(isBodyFullyVisible ? "Hold still for \(countdown)..." : "Step back to fit your entire body in frame.")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .padding(.top, 40) // Safe area
                    .background(Color.black.opacity(0.8))
                    
                    Spacer()
                    
                    // Camera Flip Button
                    HStack {
                        Spacer()
                        Button(action: {
                            shouldFlipCamera = true
                        }) {
                            Image(systemName: "arrow.triangle.2.circlepath.camera")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .padding(16)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        .padding(.trailing, 24)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onChange(of: technicalImage) { newImage in
            if newImage != nil {
                processPseudo3DScan()
            }
        }
        .onChange(of: isBodyFullyVisible) { visible in
            if visible {
                startCountdown()
            } else {
                cancelCountdown()
            }
        }
        .onDisappear {
            cancelCountdown()
        }
    }
    
    private func startCountdown() {
        countdown = 2
        timer?.invalidate()
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { t in
            if countdown > 1 {
                countdown -= 1
                let tickGenerator = UIImpactFeedbackGenerator(style: .light)
                tickGenerator.impactOccurred()
            } else {
                t.invalidate()
                let snapGenerator = UIImpactFeedbackGenerator(style: .heavy)
                snapGenerator.impactOccurred()
                shouldCapture = true
            }
        }
    }
    
    private func cancelCountdown() {
        timer?.invalidate()
        timer = nil
        countdown = 2
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
