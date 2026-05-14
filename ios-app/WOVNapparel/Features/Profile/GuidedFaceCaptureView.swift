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
            Color(red: 244/255, green: 244/255, blue: 245/255).ignoresSafeArea()
            
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
            
            // Face ID Style Mask (Perfect Circle alignment)
            let circleSize = UIScreen.main.bounds.width * 0.75
            
            ZStack {
                // Crisp semi-transparent background to let camera peek through slightly, no heavy blur
                Color(red: 244/255, green: 244/255, blue: 245/255).opacity(0.95)
                    .mask(
                        Rectangle()
                            .overlay(
                                Circle()
                                    .frame(width: circleSize, height: circleSize)
                                    .blendMode(.destinationOut)
                            )
                    )
                
                // The dashed tracker ring
                Circle()
                    .stroke(progressColor, style: StrokeStyle(lineWidth: 6, lineCap: .round, dash: [10, 15]))
                    .frame(width: circleSize + 20, height: circleSize + 20)
                    .animation(.easeInOut, value: captureState)
            }
            .ignoresSafeArea()
            
            // Minimalist Top UI
            VStack {
                Text(instructionTitle)
                    .font(.system(size: 32, weight: .regular, design: .serif))
                    .foregroundColor(Color(red: 24/255, green: 24/255, blue: 27/255))
                    .padding(.top, 60)
                
                Text(instructionSubtitle)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color(red: 113/255, green: 113/255, blue: 122/255))
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
                
                Spacer()
                
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Text("CANCEL")
                        .font(.system(size: 12, weight: .semibold))
                        .tracking(2)
                        .foregroundColor(Color(red: 113/255, green: 113/255, blue: 122/255))
                        .padding()
                }
                .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.light)
    }
    
    private var instructionTitle: String {
        switch captureState {
        case .initializing: return "Face ID Setup"
        case .alignStraight: return "How to Set Up Face ID"
        case .capturingStraight: return "Hold Still..."
        case .turnLeft: return "Move your head slowly"
        case .capturingLeft: return "Hold Still..."
        case .turnRight: return "Move your head slowly"
        case .capturingRight: return "Hold Still..."
        case .complete: return "Face ID is Set Up"
        }
    }
    
    private var instructionSubtitle: String {
        switch captureState {
        case .alignStraight: return "First, position your face in the camera frame.\nThen move your head in a circle to show all the angles of your face."
        case .turnLeft: return "Turn your head to the left."
        case .turnRight: return "Turn your head to the right."
        case .complete: return "Your face has been successfully scanned."
        default: return ""
        }
    }
    
    private var progressColor: Color {
        switch captureState {
        case .capturingStraight, .capturingLeft, .capturingRight, .complete:
            return .green
        default:
            return .gray.opacity(0.5)
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
        arView.backgroundColor = .black
        
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
        
        // This adds the exact Face ID 3D wireframe mesh over the user's face!
        func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
            guard let device = renderer.device, anchor is ARFaceAnchor else { return nil }
            let faceGeometry = ARSCNFaceGeometry(device: device)
            let node = SCNNode(geometry: faceGeometry)
            
            // Render as a futuristic green wireframe
            node.geometry?.firstMaterial?.fillMode = .lines
            node.geometry?.firstMaterial?.diffuse.contents = UIColor.systemGreen.withAlphaComponent(0.8)
            node.geometry?.firstMaterial?.lightingModel = .constant
            
            return node
        }
        
        func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
            guard let faceAnchor = anchor as? ARFaceAnchor, !isCapturing else { return }
            
            // Update the wireframe geometry to match the face expressions in real time
            if let faceGeometry = node.geometry as? ARSCNFaceGeometry {
                faceGeometry.update(from: faceAnchor.geometry)
            }
            
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
                    
                    // Do not apply viewport displayTransform as it squashes the 16:9 camera feed into the screen aspect ratio.
                    // Instead, create the CGImage directly from the raw pixel buffer and rely on UIImage orientation.
                    if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
                        // ARKit front camera feeds are landscape. We use .leftMirrored to rotate to portrait and mirror for selfie view.
                        let uiImage = UIImage(cgImage: cgImage, scale: 1.0, orientation: .leftMirrored)
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
