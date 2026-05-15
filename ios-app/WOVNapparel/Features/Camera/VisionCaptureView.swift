import SwiftUI

struct VisionCaptureView: UIViewControllerRepresentable {
    @Binding var isBodyFullyVisible: Bool
    @Binding var boundingBox: CGRect
    @Binding var capturedImage: UIImage?
    
    // An external trigger to fire the capture from SwiftUI (e.g. after countdown)
    @Binding var shouldCapture: Bool
    
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
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, VisionCaptureDelegate {
        var parent: VisionCaptureView
        
        init(_ parent: VisionCaptureView) {
            self.parent = parent
        }
        
        func visionCapture(_ controller: VisionCaptureController, didUpdateBodyState isBodyFullyVisible: Bool, boundingBox: CGRect) {
            parent.isBodyFullyVisible = isBodyFullyVisible
            parent.boundingBox = boundingBox
        }
        
        func visionCapture(_ controller: VisionCaptureController, didCapturePhoto photo: UIImage) {
            parent.capturedImage = photo
        }
    }
}
