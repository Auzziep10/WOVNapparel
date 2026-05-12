import ARKit
import Vision
import CoreMedia
import RealityKit

@available(iOS 14.0, *)
class LiDARSizingEngine: NSObject, ARSessionDelegate, ObservableObject {
    
    // We keep a reference to the active session to grab the depth map
    weak var activeSession: ARSession?
    
    // MARK: - Core Resolution Engine
    func resolveUserSizing(userId: String, image: CVPixelBuffer) async throws -> [String: Double] {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNDetectHumanBodyPoseRequest { [weak self] req, err in
                if let err = err {
                    continuation.resume(throwing: err)
                    return
                }
                
                guard let results = req.results as? [VNHumanBodyPoseObservation], let body = results.first else {
                    continuation.resume(throwing: NSError(domain: "LiDARSizingEngine", code: 1, userInfo: [NSLocalizedDescriptionKey: "No human body detected."]))
                    return
                }
                
                do {
                    let metrics = try self?.extractTrue3DMetrics(from: body) ?? [:]
                    continuation.resume(returning: metrics)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
            
            let handler = VNImageRequestHandler(cvPixelBuffer: image, orientation: .up, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    // MARK: - 3D Sensor Fusion
    private func extractTrue3DMetrics(from body: VNHumanBodyPoseObservation) throws -> [String: Double] {
        guard let currentFrame = activeSession?.currentFrame,
              let depthData = currentFrame.sceneDepth else {
            throw NSError(domain: "LiDARSizingEngine", code: 2, userInfo: [NSLocalizedDescriptionKey: "LiDAR depth map not available."])
        }
        
        let depthMap = depthData.depthMap
        let intrinsics = currentFrame.camera.intrinsics
        let imageResolution = currentFrame.camera.imageResolution
        
        CVPixelBufferLockBaseAddress(depthMap, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(depthMap, .readOnly) }
        
        guard let baseAddress = CVPixelBufferGetBaseAddress(depthMap)?.assumingMemoryBound(to: Float32.self) else {
            throw NSError(domain: "LiDARSizingEngine", code: 3, userInfo: [NSLocalizedDescriptionKey: "Could not read LiDAR memory buffer."])
        }
        
        let depthWidth = CVPixelBufferGetWidth(depthMap)
        let depthHeight = CVPixelBufferGetHeight(depthMap)
        
        // Helper: Convert normalized Vision point to 3D World point
        func get3DPoint(for joint: VNHumanBodyPoseObservation.JointName) -> simd_float3? {
            guard let point = try? body.recognizedPoint(joint), point.confidence > 0.5 else { return nil }
            
            // Vision returns coordinates normalized (0.0 to 1.0) with origin at bottom-left
            // We must convert to image resolution coordinates (origin top-left)
            let pixelX = point.location.x * CGFloat(imageResolution.width)
            let pixelY = (1.0 - point.location.y) * CGFloat(imageResolution.height)
            
            // Map image coordinate to depth map coordinate
            let scaleX = CGFloat(depthWidth) / CGFloat(imageResolution.width)
            let scaleY = CGFloat(depthHeight) / CGFloat(imageResolution.height)
            
            let depthX = Int(pixelX * scaleX)
            let depthY = Int(pixelY * scaleY)
            
            // Safety bounds check
            guard depthX >= 0, depthX < depthWidth, depthY >= 0, depthY < depthHeight else { return nil }
            
            let index = (depthY * depthWidth) + depthX
            let zDistanceInMeters = baseAddress[index]
            
            // Unproject 2D + Depth to 3D using pinhole camera model
            // x = (u - cx) * z / fx
            // y = (v - cy) * z / fy
            let u = Float(pixelX)
            let v = Float(pixelY)
            let fx = intrinsics[0][0]
            let fy = intrinsics[1][1]
            let cx = intrinsics[2][0]
            let cy = intrinsics[2][1]
            
            let x = (u - cx) * zDistanceInMeters / fx
            let y = (v - cy) * zDistanceInMeters / fy
            
            return simd_float3(x, y, zDistanceInMeters)
        }
        
        guard let leftShoulder3D = get3DPoint(for: .leftShoulder),
              let rightShoulder3D = get3DPoint(for: .rightShoulder),
              let leftHip3D = get3DPoint(for: .leftHip),
              let rightHip3D = get3DPoint(for: .rightHip) else {
            throw NSError(domain: "LiDARSizingEngine", code: 4, userInfo: [NSLocalizedDescriptionKey: "Insufficient skeletal joints visible."])
        }
        
        // Calculate true euclidean distances in meters
        let chestWidthMeters = distance(leftShoulder3D, rightShoulder3D)
        let waistWidthMeters = distance(leftHip3D, rightHip3D)
        
        // Convert to CM Circumference (approximate human cylinder)
        let chestCircumferenceCm = Double(chestWidthMeters * .pi * 100)
        let waistCircumferenceCm = Double(waistWidthMeters * .pi * 100)
        
        return [
            "chestCm": chestCircumferenceCm,
            "waistCm": waistCircumferenceCm,
            "hipsCm": waistCircumferenceCm * 1.1 // Rough estimation for hips
        ]
    }
}
