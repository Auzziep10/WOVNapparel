import SwiftUI

struct SkeletalLine: Equatable, Identifiable {
    let id = UUID()
    let start: CGPoint
    let end: CGPoint
}

struct VisionCaptureView: UIViewControllerRepresentable {
    @Binding var isBodyFullyVisible: Bool
    @Binding var boundingBox: CGRect
    @Binding var joints: [CGPoint]
    @Binding var lines: [SkeletalLine]
    
    @Binding var capturedImage: UIImage?
    
    // An external trigger to fire the capture from SwiftUI (e.g. after countdown)
    @Binding var shouldCapture: Bool
    
    // Trigger to flip the camera
    @Binding var shouldFlipCamera: Bool
    
    func makeUIViewController(context: Context) -> VisionCaptureController {
        let controller = VisionCaptureController()
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: VisionCaptureController, context: Context) {
        if shouldCapture {
            DispatchQueue.main.async {
                self.shouldCapture = false // reset the trigger immediately
                uiViewController.capturePhotoNow()
            }
        }
        
        if shouldFlipCamera {
            DispatchQueue.main.async {
                self.shouldFlipCamera = false
                uiViewController.flipCamera()
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, VisionCaptureDelegate {
        var parent: VisionCaptureView
        
        init(_ parent: VisionCaptureView) {
            self.parent = parent
        }
        
        func visionCapture(_ controller: VisionCaptureController, didUpdateBodyState isBodyFullyVisible: Bool, boundingBox: CGRect, joints: [CGPoint], lines: [(CGPoint, CGPoint)]) {
            parent.isBodyFullyVisible = isBodyFullyVisible
            parent.boundingBox = boundingBox
            parent.joints = joints
            parent.lines = lines.map { SkeletalLine(start: $0.0, end: $0.1) }
        }
        
        func visionCapture(_ controller: VisionCaptureController, didCapturePhoto photo: UIImage) {
            parent.capturedImage = photo
        }
    }
}
