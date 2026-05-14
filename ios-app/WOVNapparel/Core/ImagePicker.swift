import SwiftUI
import UIKit

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) private var presentationMode
    
    var sourceType: UIImagePickerController.SourceType = .camera
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> UIImagePickerController {
        let imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = false
        imagePicker.sourceType = sourceType
        imagePicker.delegate = context.coordinator
        
        if sourceType == .camera {
            // Add a simple automatic timer overlay
            let overlay = UIView(frame: UIScreen.main.bounds)
            overlay.isUserInteractionEnabled = false // Allow taps to pass through to native controls
            
            let label = UILabel(frame: CGRect(x: 0, y: 100, width: UIScreen.main.bounds.width, height: 100))
            label.textAlignment = .center
            label.textColor = .white
            label.font = UIFont.systemFont(ofSize: 72, weight: .bold)
            label.layer.shadowColor = UIColor.black.cgColor
            label.layer.shadowOffset = .zero
            label.layer.shadowOpacity = 0.5
            label.layer.shadowRadius = 5
            
            overlay.addSubview(label)
            imagePicker.cameraOverlayView = overlay
            
            // Start countdown
            context.coordinator.startTimer(label: label, picker: imagePicker)
        }
        
        return imagePicker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<ImagePicker>) {
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var parent: ImagePicker
        var timer: Timer?
        var timeRemaining = 10
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func startTimer(label: UILabel, picker: UIImagePickerController) {
            label.text = "\(timeRemaining)"
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] t in
                guard let self = self else { return }
                self.timeRemaining -= 1
                
                if self.timeRemaining > 0 {
                    label.text = "\(self.timeRemaining)"
                } else {
                    label.text = ""
                    t.invalidate()
                    picker.takePicture()
                }
            }
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
