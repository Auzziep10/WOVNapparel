import UIKit
import AVFoundation
import Vision

protocol VisionCaptureDelegate: AnyObject {
    /// Called every frame with the state of the body tracking.
    /// - Parameters:
    ///   - isBodyFullyVisible: True if all major joints (head to ankles) are in frame and the person is far enough away.
    ///   - boundingBox: The UIKit-coordinate bounding box of the detected body.
    func visionCapture(_ controller: VisionCaptureController, didUpdateBodyState isBodyFullyVisible: Bool, boundingBox: CGRect)
    
    /// Called when the photo is automatically captured.
    func visionCapture(_ controller: VisionCaptureController, didCapturePhoto photo: UIImage)
}

class VisionCaptureController: UIViewController {
    
    weak var delegate: VisionCaptureDelegate?
    
    private let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let photoOutput = AVCapturePhotoOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer!
    
    // Auto-Capture State
    private var isCapturing = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let previewLayer = previewLayer {
            previewLayer.frame = view.bounds
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }
    
    private func setupCamera() {
        captureSession.sessionPreset = .photo
        
        guard let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: captureDevice) else {
            print("Failed to access camera")
            return
        }
        
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }
        
        // Video Data Output for Vision Tracking
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "vision_queue"))
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
        
        // Photo Output for high-res final capture
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        }
        
        // Ensure video is properly oriented (Portrait)
        if let connection = videoOutput.connection(with: .video), connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
        }
        if let connection = photoOutput.connection(with: .video), connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        DispatchQueue.global(qos: .background).async {
            self.captureSession.startRunning()
        }
    }
    
    func capturePhotoNow() {
        guard !isCapturing else { return }
        isCapturing = true
        
        let settings = AVCapturePhotoSettings()
        settings.isHighResolutionPhotoEnabled = false
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
}

extension VisionCaptureController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard !isCapturing else { return }
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let request = VNDetectHumanBodyPoseRequest { [weak self] request, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Vision error: \(error)")
                return
            }
            
            guard let results = request.results as? [VNHumanBodyPoseObservation], let pose = results.first else {
                // No body found
                DispatchQueue.main.async {
                    self.delegate?.visionCapture(self, didUpdateBodyState: false, boundingBox: .zero)
                }
                return
            }
            
            self.analyzePose(pose)
        }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        try? handler.perform([request])
    }
    
    private func analyzePose(_ pose: VNHumanBodyPoseObservation) {
        // We require specific joints to ensure the full body is in frame
        let requiredJointNames: [VNHumanBodyPoseObservation.JointName] = [
            .nose, .leftWrist, .rightWrist, .leftAnkle, .rightAnkle
        ]
        
        var isFullyVisible = true
        var allPoints: [CGPoint] = []
        
        do {
            let recognizedPoints = try pose.recognizedPoints(.all)
            
            // Check if essential joints are visible and have high enough confidence
            for jointName in requiredJointNames {
                if let point = recognizedPoints[jointName], point.confidence > 0.3 {
                    // Points are normalized 0-1 with origin at bottom-left
                    allPoints.append(point.location)
                } else {
                    isFullyVisible = false
                }
            }
            
            // Collect all high confidence points to build a bounding box
            for (_, point) in recognizedPoints where point.confidence > 0.3 {
                allPoints.append(point.location)
            }
            
        } catch {
            isFullyVisible = false
        }
        
        // Calculate Bounding Box
        var boundingBox: CGRect = .zero
        if !allPoints.isEmpty {
            let minX = allPoints.map { $0.x }.min()!
            let maxX = allPoints.map { $0.x }.max()!
            let minY = allPoints.map { $0.y }.min()!
            let maxY = allPoints.map { $0.y }.max()!
            
            // Vision coordinates have origin at bottom-left. We must flip Y.
            // Also, we pad the box slightly so it looks better as a UI element.
            let padding: CGFloat = 0.05
            
            let normalizedRect = CGRect(
                x: max(0, minX - padding),
                y: max(0, (1.0 - maxY) - padding), // Flip Y
                width: min(1.0, (maxX - minX) + (padding * 2)),
                height: min(1.0, (maxY - minY) + (padding * 2))
            )
            
            // Translate to UIKit coordinates synchronously on main thread
            DispatchQueue.main.sync {
                let screenRect = previewLayer.layerRectConverted(fromMetadataOutputRect: normalizedRect)
                boundingBox = screenRect
            }
        }
        
        // Ensure the person is taking up a good amount of the screen, but not overflowing.
        // A full body should have a height between 50% and 90% of the screen.
        let bodyHeightRatio = boundingBox.height / UIScreen.main.bounds.height
        if bodyHeightRatio < 0.5 || bodyHeightRatio > 0.95 {
            isFullyVisible = false
        }
        
        DispatchQueue.main.async {
            self.delegate?.visionCapture(self, didUpdateBodyState: isFullyVisible, boundingBox: boundingBox)
        }
    }
}

extension VisionCaptureController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let data = photo.fileDataRepresentation(), let image = UIImage(data: data) {
            DispatchQueue.main.async {
                self.delegate?.visionCapture(self, didCapturePhoto: image)
            }
        } else {
            isCapturing = false // Reset if failed
        }
    }
}
