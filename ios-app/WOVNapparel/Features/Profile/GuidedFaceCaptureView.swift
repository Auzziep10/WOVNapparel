import SwiftUI
import ARKit
import SceneKit

struct GuidedFaceCaptureView: View {
    @Environment(\.presentationMode) var presentationMode
    
    // Binding to pass the images back
    @Binding var faceImage: UIImage?
    @Binding var profileImage: UIImage?
    
    @State private var captureState: FaceCaptureState = .alignStraight
    @State private var progress: CGFloat = 0.0
    
    enum FaceCaptureState {
        case initializing
        case alignStraight
        case capturingStraight
        case turnLeft
        case capturingLeft
        case turnRight
        case capturingRight
        case complete
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // The AR View
            ARFaceTrackingViewContainer(
                captureState: $captureState,
                progress: $progress,
                onCapturedStraight: { image in
                    self.faceImage = image
                    self.captureState = .turnLeft
                },
                onCapturedLeft: { image in
                    // We only need one profile image, but taking left/right ensures symmetry
                    self.profileImage = image
                    self.captureState = .turnRight
                },
                onCapturedRight: { image in
                    self.captureState = .complete
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            )
            .ignoresSafeArea()
            
            // UI Overlay
            VStack {
                HStack {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Text("Cancel")
                            .foregroundColor(.white)
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                    }
                    Spacer()
                }
                .padding()
                
                Spacer()
                
                // Guidance Text
                VStack(spacing: 12) {
                    Text(instructionTitle)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(instructionSubtitle)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding(24)
                .background(.ultraThinMaterial)
                .cornerRadius(24)
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.3), lineWidth: 1))
                .padding(.horizontal, 40)
                .padding(.bottom, 60)
            }
            
            // Mask Overlay
            GeometryReader { proxy in
                let width = proxy.size.width * 0.8
                let height = proxy.size.height * 0.55
                
                ZStack {
                    // Darken everything outside the oval
                    Color.black.opacity(0.6)
                        .mask(
                            Rectangle()
                                .overlay(
                                    Ellipse()
                                        .frame(width: width, height: height)
                                        .blendMode(.destinationOut)
                                )
                        )
                        .ignoresSafeArea()
                    
                    // The glowing outline
                    Ellipse()
                        .stroke(progressColor, lineWidth: 4)
                        .frame(width: width, height: height)
                        .blur(radius: 2)
                        .animation(.easeInOut, value: captureState)
                    
                    // The actual stroke
                    Ellipse()
                        .stroke(Color.white.opacity(0.5), lineWidth: 2)
                        .frame(width: width, height: height)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private var instructionTitle: String {
        switch captureState {
        case .initializing: return "Starting Camera..."
        case .alignStraight: return "Look Straight"
        case .capturingStraight: return "Hold Still..."
        case .turnLeft: return "Turn Slowly Left"
        case .capturingLeft: return "Hold Still..."
        case .turnRight: return "Turn Slowly Right"
        case .capturingRight: return "Hold Still..."
        case .complete: return "Capture Complete!"
        }
    }
    
    private var instructionSubtitle: String {
        switch captureState {
        case .alignStraight: return "Position your face inside the frame"
        case .turnLeft: return "Keep your phone steady and turn your head left"
        case .turnRight: return "Now turn your head slowly to the right"
        case .complete: return "Processing your visual identity"
        default: return ""
        }
    }
    
    private var progressColor: Color {
        switch captureState {
        case .capturingStraight, .capturingLeft, .capturingRight, .complete:
            return .green
        default:
            return .blue
        }
    }
}

struct ARFaceTrackingViewContainer: UIViewRepresentable {
    @Binding var captureState: GuidedFaceCaptureView.FaceCaptureState
    @Binding var progress: CGFloat
    
    var onCapturedStraight: (UIImage) -> Void
    var onCapturedLeft: (UIImage) -> Void
    var onCapturedRight: (UIImage) -> Void
    
    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView(frame: .zero)
        arView.delegate = context.coordinator
        arView.automaticallyUpdatesLighting = true
        
        let config = ARFaceTrackingConfiguration()
        arView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
        
        return arView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, ARSCNViewDelegate {
        var parent: ARFaceTrackingViewContainer
        var isCapturing = false
        
        init(_ parent: ARFaceTrackingViewContainer) {
            self.parent = parent
        }
        
        func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
            guard let faceAnchor = anchor as? ARFaceAnchor, !isCapturing else { return }
            
            let yaw = node.eulerAngles.y
            
            DispatchQueue.main.async {
                self.processYaw(yaw, session: (renderer as? ARSCNView)?.session)
            }
        }
        
        private func processYaw(_ yaw: Float, session: ARSession?) {
            switch parent.captureState {
            case .alignStraight:
                // Straight means yaw is near 0
                if abs(yaw) < 0.15 {
                    triggerCapture(state: .capturingStraight, session: session, callback: parent.onCapturedStraight)
                }
            case .turnLeft:
                // Turned left
                if yaw < -0.55 {
                    triggerCapture(state: .capturingLeft, session: session, callback: parent.onCapturedLeft)
                }
            case .turnRight:
                // Turned right
                if yaw > 0.55 {
                    triggerCapture(state: .capturingRight, session: session, callback: parent.onCapturedRight)
                }
            default:
                break
            }
        }
        
        private func triggerCapture(state: GuidedFaceCaptureView.FaceCaptureState, session: ARSession?, callback: @escaping (UIImage) -> Void) {
            isCapturing = true
            parent.captureState = state
            
            // Haptic feedback
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            
            // Wait a fraction of a second to ensure they are holding still, then grab frame
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if let frame = session?.currentFrame {
                    let pixelBuffer = frame.capturedImage
                    let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
                    let context = CIContext()
                    
                    // Must apply transform to orient correctly (CVPixelBuffer is typically landscape right from camera)
                    let transform = frame.displayTransform(for: .portrait, viewportSize: UIScreen.main.bounds.size)
                    let transformedCI = ciImage.transformed(by: CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -ciImage.extent.height)).transformed(by: transform)

                    if let cgImage = context.createCGImage(transformedCI, from: transformedCI.extent) {
                        let uiImage = UIImage(cgImage: cgImage, scale: 1.0, orientation: .up)
                        callback(uiImage)
                        
                        // Small delay before allowing next capture to prevent double fires
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.isCapturing = false
                        }
                    } else {
                        self.isCapturing = false
                    }
                } else {
                    self.isCapturing = false
                }
            }
        }
    }
}
