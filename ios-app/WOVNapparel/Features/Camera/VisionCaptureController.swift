import UIKit
import AVFoundation
import Vision

protocol VisionCaptureDelegate: AnyObject {
    /// Called every frame with the state of the body tracking.
    /// - Parameters:
    ///   - isBodyFullyVisible: True if all major joints (head to ankles) are in frame and the person is far enough away.
    ///   - boundingBox: The UIKit-coordinate bounding box of the detected body.
    ///   - joints: The screen coordinates of all detected joints.
    ///   - lines: The pairs of screen coordinates to connect with lines to draw the skeleton.
    func visionCapture(_ controller: VisionCaptureController, didUpdateBodyState isBodyFullyVisible: Bool, boundingBox: CGRect, joints: [CGPoint], lines: [(CGPoint, CGPoint)])
    
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
    
    private var isFrontCamera = false
    
    func flipCamera() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            self.captureSession.beginConfiguration()
            
            // Remove existing input
            guard let currentInput = self.captureSession.inputs.first as? AVCaptureDeviceInput else {
                self.captureSession.commitConfiguration()
                return
            }
            self.captureSession.removeInput(currentInput)
            
            // Toggle camera position
            self.isFrontCamera.toggle()
            let newPosition: AVCaptureDevice.Position = self.isFrontCamera ? .front : .back
            
            guard let newDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition),
                  let newInput = try? AVCaptureDeviceInput(device: newDevice) else {
                // Revert if failed
                self.captureSession.addInput(currentInput)
                self.isFrontCamera.toggle()
                self.captureSession.commitConfiguration()
                return
            }
            
            if self.captureSession.canAddInput(newInput) {
                self.captureSession.addInput(newInput)
            } else {
                self.captureSession.addInput(currentInput)
                self.isFrontCamera.toggle()
            }
            
            // Re-apply video orientation
            if let connection = self.videoOutput.connection(with: .video), connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
                // Fix mirroring for front camera tracking
                connection.isVideoMirrored = self.isFrontCamera
            }
            
            self.captureSession.commitConfiguration()
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
                    self.delegate?.visionCapture(self, didUpdateBodyState: false, boundingBox: .zero, joints: [], lines: [])
                }
                return
            }
            
            self.analyzePose(pose)
        }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        try? handler.perform([request])
    }
    
    private func analyzePose(_ pose: VNHumanBodyPoseObservation) {
        // We require specific joints to ensure the full body is in frame.
        // Reverted back to strict ankle requirement for accurate full-body metrics.
        let requiredJointNames: [VNHumanBodyPoseObservation.JointName] = [
            .nose, .leftWrist, .rightWrist, .leftAnkle, .rightAnkle
        ]
        
        var isFullyVisible = true
        var allNormalizedPoints: [CGPoint] = []
        var jointDict: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
        
        do {
            let recognizedPoints = try pose.recognizedPoints(.all)
            
            // Collect all high confidence points
            for (jointName, point) in recognizedPoints where point.confidence > 0.2 {
                jointDict[jointName] = point.location
                allNormalizedPoints.append(point.location)
            }
            
            // Check required joints
            for jointName in requiredJointNames {
                if jointDict[jointName] == nil {
                    isFullyVisible = false
                }
            }
            
        } catch {
            isFullyVisible = false
        }
        
        // Calculate Bounding Box
        var boundingBox: CGRect = .zero
        var screenJoints: [CGPoint] = []
        var screenLines: [(CGPoint, CGPoint)] = []
        
        if !allNormalizedPoints.isEmpty {
            let minX = allNormalizedPoints.map { $0.x }.min()!
            let maxX = allNormalizedPoints.map { $0.x }.max()!
            let minY = allNormalizedPoints.map { $0.y }.min()!
            let maxY = allNormalizedPoints.map { $0.y }.max()!
            
            let padding: CGFloat = 0.05
            
            // Vision points are 0..1 where (0,0) is bottom-left of the buffer.
            // Since we forced connection.videoOrientation = .portrait, the buffer is portrait.
            // The aspect ratio of the .photo preset is 3:4 (portrait).
            let cameraAspect: CGFloat = 3.0 / 4.0
            
            // Calculate screen dimensions to perform a perfect .resizeAspectFill mapping
            let screenBounds = UIScreen.main.bounds
            let screenAspect = screenBounds.width / screenBounds.height
            
            var scaleX: CGFloat = 1.0
            var scaleY: CGFloat = 1.0
            var offsetX: CGFloat = 0.0
            var offsetY: CGFloat = 0.0
            
            if screenAspect < cameraAspect {
                // Screen is narrower than the camera feed. Left and right are cropped.
                scaleY = screenBounds.height
                scaleX = screenBounds.height * cameraAspect
                offsetX = -(scaleX - screenBounds.width) / 2.0
            } else {
                // Screen is wider than the camera feed. Top and bottom are cropped.
                scaleX = screenBounds.width
                scaleY = screenBounds.width / cameraAspect
                offsetY = -(scaleY - screenBounds.height) / 2.0
            }
            
            // Helper to convert a normalized Vision point to exact SwiftUI screen coordinates
            func convertPoint(_ point: CGPoint) -> CGPoint {
                let x = point.x
                let y = 1.0 - point.y // Flip Y
                
                return CGPoint(x: x * scaleX + offsetX, y: y * scaleY + offsetY)
            }
            
            DispatchQueue.main.sync {
                // Map all joints to screen coordinates
                screenJoints = jointDict.values.map { convertPoint($0) }
                
                // Define connections to draw the skeleton
                let connections: [(VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName)] = [
                    (.nose, .neck),
                    (.neck, .leftShoulder), (.leftShoulder, .leftElbow), (.leftElbow, .leftWrist),
                    (.neck, .rightShoulder), (.rightShoulder, .rightElbow), (.rightElbow, .rightWrist),
                    (.neck, .root),
                    (.root, .leftHip), (.leftHip, .leftKnee), (.leftKnee, .leftAnkle),
                    (.root, .rightHip), (.rightHip, .rightKnee), (.rightKnee, .rightAnkle)
                ]
                
                for connection in connections {
                    if let start = jointDict[connection.0], let end = jointDict[connection.1] {
                        screenLines.append((convertPoint(start), convertPoint(end)))
                    }
                }
                
                // Calculate UI bounding box from screen joints
                if !screenJoints.isEmpty {
                    let sMinX = screenJoints.map { $0.x }.min()!
                    let sMaxX = screenJoints.map { $0.x }.max()!
                    let sMinY = screenJoints.map { $0.y }.min()!
                    let sMaxY = screenJoints.map { $0.y }.max()!
                    let sPadding: CGFloat = 20.0
                    
                    boundingBox = CGRect(
                        x: sMinX - sPadding,
                        y: sMinY - sPadding,
                        width: (sMaxX - sMinX) + (sPadding * 2),
                        height: (sMaxY - sMinY) + (sPadding * 2)
                    )
                }
            }
        }
        
        // Ensure the person is taking up a good amount of the screen.
        let bodyHeightRatio = boundingBox.height / UIScreen.main.bounds.height
        if bodyHeightRatio < 0.4 || bodyHeightRatio > 0.95 {
            isFullyVisible = false
        }
        
        DispatchQueue.main.async {
            self.delegate?.visionCapture(self, didUpdateBodyState: isFullyVisible, boundingBox: boundingBox, joints: screenJoints, lines: screenLines)
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
