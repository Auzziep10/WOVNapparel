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
            
            // Allow taps to pass through to native controls ONLY outside of our buttons
            overlay.isUserInteractionEnabled = true
            
            // Pass-through view wrapper to only intercept touches on the button
            class PassThroughView: UIView {
                override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
                    let view = super.hitTest(point, with: event)
                    return view == self ? nil : view
                }
            }
            
            let passThroughOverlay = PassThroughView(frame: UIScreen.main.bounds)
            
            let label = UILabel(frame: CGRect(x: 0, y: UIScreen.main.bounds.height / 2 - 50, width: UIScreen.main.bounds.width, height: 100))
            label.textAlignment = .center
            label.textColor = .white
            label.font = UIFont.systemFont(ofSize: 120, weight: .bold)
            label.layer.shadowColor = UIColor.black.cgColor
            label.layer.shadowOffset = .zero
            label.layer.shadowOpacity = 0.5
            label.layer.shadowRadius = 5
            label.text = "10"
            
            let startButton = UIButton(frame: CGRect(x: UIScreen.main.bounds.width / 2 - 75, y: UIScreen.main.bounds.height - 220, width: 150, height: 50))
            startButton.backgroundColor = UIColor(white: 0, alpha: 0.7)
            startButton.setTitle("START 10s TIMER", for: .normal)
            startButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .bold)
            startButton.layer.cornerRadius = 25
            
            passThroughOverlay.addSubview(label)
            passThroughOverlay.addSubview(startButton)
            
            imagePicker.cameraOverlayView = passThroughOverlay
            
            // Bind action
            let action = UIAction { _ in
                startButton.isHidden = true
                context.coordinator.startTimer(label: label, picker: imagePicker)
            }
            startButton.addAction(action, for: .touchUpInside)
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
