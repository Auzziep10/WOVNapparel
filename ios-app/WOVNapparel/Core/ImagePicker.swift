import SwiftUI
import UIKit

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) private var presentationMode
    
    var sourceType: UIImagePickerController.SourceType = .camera
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> UIImagePickerController {
        let imagePicker = CustomImagePickerController()
        imagePicker.allowsEditing = false
        imagePicker.sourceType = sourceType
        imagePicker.delegate = context.coordinator
        
        if sourceType == .camera {
            let passThroughOverlay = PassThroughView(frame: UIScreen.main.bounds)
            imagePicker.overlayView = passThroughOverlay
            
            // Countdown Label - Clean and hidden by default
            let label = UILabel()
            label.textAlignment = .center
            label.textColor = .white
            label.font = UIFont.systemFont(ofSize: 120, weight: .bold)
            label.layer.shadowColor = UIColor.black.cgColor
            label.layer.shadowOffset = .zero
            label.layer.shadowOpacity = 0.5
            label.layer.shadowRadius = 8
            label.text = ""
            label.isHidden = true
            
            passThroughOverlay.countdownLabel = label
            passThroughOverlay.addSubview(label)
            
            // Start Action
            let startAction = UIAction { _ in
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                
                if let timerView = passThroughOverlay.timerContainer, let cancelView = passThroughOverlay.cancelContainer {
                    UIView.animate(withDuration: 0.3) {
                        timerView.alpha = 0
                        cancelView.alpha = 1
                    } completion: { _ in
                        timerView.isHidden = true
                        cancelView.isHidden = false
                    }
                    
                    label.isHidden = false
                    context.coordinator.startTimer(
                        label: label,
                        picker: imagePicker,
                        timerContainer: timerView,
                        cancelContainer: cancelView
                    )
                }
            }
            
            // Cancel Action
            let cancelAction = UIAction { _ in
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                context.coordinator.resetTimerUI()
            }
            
            // Create Glassmorphic Buttons
            let timerButtonTuple = createGlassmorphicButton(
                title: "10s Timer",
                iconName: "timer",
                tintColor: .white,
                action: startAction
            )
            passThroughOverlay.timerContainer = timerButtonTuple.container
            passThroughOverlay.addSubview(timerButtonTuple.container)
            
            let cancelButtonTuple = createGlassmorphicButton(
                title: "Cancel",
                iconName: "xmark.circle",
                tintColor: UIColor(red: 255/255, green: 69/255, blue: 58/255, alpha: 1.0),
                action: cancelAction
            )
            cancelButtonTuple.container.isHidden = true
            cancelButtonTuple.container.alpha = 0
            passThroughOverlay.cancelContainer = cancelButtonTuple.container
            passThroughOverlay.addSubview(cancelButtonTuple.container)
            
            // Set interactive views for touch pass-through
            passThroughOverlay.activeInteractiveViews = [timerButtonTuple.button, cancelButtonTuple.button]
            
            imagePicker.cameraOverlayView = passThroughOverlay
        }
        
        return imagePicker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<ImagePicker>) {
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    private func createGlassmorphicButton(
        title: String,
        iconName: String,
        tintColor: UIColor,
        action: UIAction
    ) -> (container: UIView, button: UIButton) {
        let container = UIView()
        container.backgroundColor = .clear
        
        let blurEffect = UIBlurEffect(style: .dark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
        blurView.layer.borderWidth = 1.0
        
        let button = UIButton(type: .system)
        button.tintColor = tintColor
        
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .bold)
        let icon = UIImage(systemName: iconName, withConfiguration: config)
        button.setImage(icon, for: .normal)
        button.setTitle("  " + title, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .bold)
        button.addAction(action, for: .touchUpInside)
        
        container.addSubview(blurView)
        container.addSubview(button)
        
        return (container, button)
    }
    
    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var parent: ImagePicker
        var timer: Timer?
        var timeRemaining = 10
        
        weak var timerContainer: UIView?
        weak var cancelContainer: UIView?
        weak var label: UILabel?
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func startTimer(label: UILabel, picker: UIImagePickerController, timerContainer: UIView, cancelContainer: UIView) {
            self.timeRemaining = 10
            self.label = label
            self.timerContainer = timerContainer
            self.cancelContainer = cancelContainer
            
            // Play initial second tick
            playTick(label: label)
            
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] t in
                guard let self = self else { return }
                self.timeRemaining -= 1
                
                if self.timeRemaining > 0 {
                    self.playTick(label: label)
                } else {
                    self.resetTimerUI()
                    t.invalidate()
                    
                    // Native heavy haptic feedback on snapshot
                    let generator = UIImpactFeedbackGenerator(style: .heavy)
                    generator.impactOccurred()
                    
                    picker.takePicture()
                }
            }
        }
        
        func resetTimerUI() {
            timer?.invalidate()
            timer = nil
            timeRemaining = 10
            
            if let label = label {
                label.text = ""
                label.isHidden = true
            }
            
            if let timerContainer = timerContainer, let cancelContainer = cancelContainer {
                UIView.animate(withDuration: 0.3) {
                    timerContainer.alpha = 1.0
                    cancelContainer.alpha = 0.0
                } completion: { _ in
                    timerContainer.isHidden = false
                    cancelContainer.isHidden = true
                }
            }
        }
        
        private func playTick(label: UILabel) {
            label.text = "\(timeRemaining)"
            
            // Pulse haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            
            // Pop scaling micro-animation on label
            label.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
            label.alpha = 0.0
            
            UIView.animate(withDuration: 0.35, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
                label.transform = .identity
                label.alpha = 1.0
            }
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            resetTimerUI()
            if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            resetTimerUI()
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// Pass-through view wrapper to only intercept touches on specific active controls
class PassThroughView: UIView {
    var activeInteractiveViews: [UIView] = []
    
    var timerContainer: UIView?
    var cancelContainer: UIView?
    var countdownLabel: UILabel?
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        if let view = view {
            var current: UIView? = view
            while current != nil {
                if activeInteractiveViews.contains(current!) {
                    return view
                }
                current = current?.superview
            }
        }
        return nil
    }
    
    func updateLayout(safeAreaInsets: UIEdgeInsets) {
        let topPadding = max(safeAreaInsets.top, 20.0) + 12.0
        
        if let timerContainer = timerContainer {
            timerContainer.frame = CGRect(
                x: 20,
                y: topPadding,
                width: 120,
                height: 40
            )
            if let blur = timerContainer.subviews.first as? UIVisualEffectView {
                blur.layer.cornerRadius = 20
                blur.layer.masksToBounds = true
                blur.frame = timerContainer.bounds
            }
            if let button = timerContainer.subviews.last as? UIButton {
                button.frame = timerContainer.bounds
            }
        }
        
        let bottomPadding = max(safeAreaInsets.bottom, 20.0)
        let cancelY = bounds.height - bottomPadding - 140
        
        if let cancelContainer = cancelContainer {
            cancelContainer.frame = CGRect(
                x: bounds.width / 2 - 60,
                y: cancelY,
                width: 120,
                height: 40
            )
            if let blur = cancelContainer.subviews.first as? UIVisualEffectView {
                blur.layer.cornerRadius = 20
                blur.layer.masksToBounds = true
                blur.frame = cancelContainer.bounds
            }
            if let button = cancelContainer.subviews.last as? UIButton {
                button.frame = cancelContainer.bounds
            }
        }
        
        countdownLabel?.frame = CGRect(
            x: 0,
            y: bounds.height / 2 - 75,
            width: bounds.width,
            height: 150
        )
    }
}

class CustomImagePickerController: UIImagePickerController {
    var overlayView: PassThroughView?
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let overlay = overlayView {
            overlay.frame = view.bounds
            overlay.updateLayout(safeAreaInsets: view.safeAreaInsets)
        }
    }
}
