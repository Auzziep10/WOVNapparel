import SwiftUI

struct CameraView: View {
    @EnvironmentObject var appState: AppFlowState
    @AppStorage("userHeightInput") private var userHeightInput: String = ""
    @AppStorage("userBodyType") private var userBodyType: String = "Average"
    
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
                
                // Premium Digital Mesh Overlay
                ZStack {
                    // 1. Active Scanning Laser Area
                    if boundingBox != .zero {
                        Rectangle()
                            .fill((isBodyFullyVisible ? Color.green : Color.yellow).opacity(0.1))
                            .frame(width: boundingBox.width, height: boundingBox.height)
                            .border((isBodyFullyVisible ? Color.green : Color.yellow).opacity(0.3), width: 1)
                            .position(x: boundingBox.midX, y: boundingBox.midY)
                            .animation(.easeInOut, value: boundingBox)
                    }
                    
                    // 2. High-Tech Wireframe Mesh
                    ForEach(lines) { line in
                        // Glowing Aura
                        Path { path in
                            path.move(to: line.start)
                            path.addLine(to: line.end)
                        }
                        .stroke(isBodyFullyVisible ? Color.green.opacity(0.6) : Color.yellow.opacity(0.6), lineWidth: 6)
                        .blur(radius: 4)
                        .animation(.interactiveSpring(), value: line)
                        
                        // Core Mesh Line
                        Path { path in
                            path.move(to: line.start)
                            path.addLine(to: line.end)
                        }
                        .stroke(Color.white.opacity(0.9), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                        .animation(.interactiveSpring(), value: line)
                    }
                    
                    // 3. Digital Tracker Nodes
                    ForEach(0..<joints.count, id: \.self) { i in
                        ZStack {
                            // Outer Node Glow
                            Circle()
                                .fill(isBodyFullyVisible ? Color.green.opacity(0.5) : Color.yellow.opacity(0.5))
                                .frame(width: 16, height: 16)
                                .blur(radius: 2)
                            
                            // Core Digital Dot
                            Circle()
                                .fill(Color.white)
                                .frame(width: 4, height: 4)
                        }
                        .position(joints[i])
                        .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.6), value: joints[i])
                    }
                }
                .allowsHitTesting(false)
                .ignoresSafeArea()
                
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
    
    static func parseHeightToCm(_ input: String) -> Double {
        let clean = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if clean.isEmpty { return 170.0 }
        
        // 1. Check for feet/inches formats: e.g. 5'10", 5ft 10in, 5 10
        if clean.contains("'") || clean.contains("ft") || clean.contains("feet") || clean.contains("foot") {
            let components = clean.components(separatedBy: CharacterSet.decimalDigits.inverted)
                .filter { !$0.isEmpty }
            if components.count >= 2 {
                if let feet = Double(components[0]), let inches = Double(components[1]) {
                    return (feet * 12 + inches) * 2.54
                }
            } else if components.count == 1 {
                if let feet = Double(components[0]) {
                    return (feet * 12) * 2.54
                }
            }
        }
        
        // 2. Check for explicit inches: e.g. 70", 70 in
        if clean.contains("\"") || clean.contains("in") || clean.contains("inch") {
            let components = clean.components(separatedBy: CharacterSet.decimalDigits.inverted)
                .filter { !$0.isEmpty }
            if let inches = Double(components.joined()) {
                return inches * 2.54
            }
        }
        
        // 3. Check for explicit cm
        if clean.contains("cm") || clean.contains("centimeter") {
            let components = clean.components(separatedBy: CharacterSet.decimalDigits.inverted)
                .filter { !$0.isEmpty }
            if let cm = Double(components.joined()) {
                return cm
            }
        }
        
        // 4. Try parsing space/dash separated numbers (e.g. "5 10", "5-10")
        let separators = CharacterSet(charactersIn: " -:,")
        let parts = clean.components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: CharacterSet.decimalDigits.inverted) }
            .filter { !$0.isEmpty }
        if parts.count >= 2 {
            if let feet = Double(parts[0]), let inches = Double(parts[1]) {
                if feet < 9 && inches < 12 {
                    return (feet * 12 + inches) * 2.54
                }
            }
        }
        
        // 5. Fallback digits-only heuristic
        let digitsOnly = clean.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        if let val = Double(digitsOnly) {
            if val < 100 { // Assume inches if less than 100
                return val * 2.54
            } else {
                return val
            }
        }
        
        return 170.0
    }
    
    private func processPseudo3DScan() {
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            
            DispatchQueue.main.async { self.processText = "Extrapolating Z-Axis Depth..." }
            
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            
            if let image = technicalImage {
                let parsedHeight = CameraView.parseHeightToCm(userHeightInput)
                
                do {
                    // Extract exact measurements from this specific technical photo
                    appState.userMetrics = try await sizingEngine.resolveUserSizing(userId: "current_user", actualHeightCm: parsedHeight, bodyType: userBodyType, image: image)
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
