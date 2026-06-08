import Foundation
import Vision
import CoreGraphics
import UIKit
import ImageIO

extension CGImagePropertyOrientation {
    init(_ uiOrientation: UIImage.Orientation) {
        switch uiOrientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}

/// SpatialSizingEngine manages the LiDAR Bypass Logic Fork and 2D Sizing Fallback.
/// It uses Firebase state to determine whether to skip 2D projection or run the math.
public class SpatialSizingEngine {
    
    // MARK: - Initialization
    
    public init() {}
    
    // MARK: - Public API
    
    /// Entry point for sizing a user. Checks Firebase for LiDAR bypass.
    /// - Parameters:
    ///   - userId: The user's ID
    ///   - actualHeightCm: The user's manually inputted height in cm.
    ///   - image: A full-body 2D selfie (used if LiDAR is not verified).
    /// - Returns: A dictionary of approximated circumferences.
    public func resolveUserSizing(userId: String, actualHeightCm: Double, bodyType: String, image: UIImage?) async throws -> [String: Double] {
        // 1. Check LiDAR Bypass
        let hasVerifiedLiDAR = try await checkLiDARBypass(for: userId)
        
        if hasVerifiedLiDAR {
            // Bypass 2D logic. Use cached metrics from Firestore.
            return try await fetchCached3DMetrics(for: userId)
        }
        
        // 2. Non-LiDAR Path: 2D Height-Constrained Projection
        guard let selfie = image else {
            throw SizingError.missingFallbackImage
        }
        
        return try await calculate2DProjection(heightCm: actualHeightCm, bodyType: bodyType, image: selfie)
    }
    
    // MARK: - Private Methods
    
    private func checkLiDARBypass(for userId: String) async throws -> Bool {
        // Pseudo-implementation: Query Firebase Auth/Firestore
        // db.collection("users").document(userId).getDocument() -> hasVerifiedLiDARProfile
        return false // Defaults to false for scaffold
    }
    
    private func fetchCached3DMetrics(for userId: String) async throws -> [String: Double] {
        // Pseudo-implementation: Fetch circumferences calculated via Mesh Decimation
        return ["chestCm": 105.0, "waistCm": 85.0, "hipsCm": 100.0]
    }
    
    private func calculate2DProjection(heightCm: Double, bodyType: String, image: UIImage) async throws -> [String: Double] {
        guard let cgImage = image.cgImage else {
            throw SizingError.missingFallbackImage
        }
        
        let orientation = CGImagePropertyOrientation(image.imageOrientation)
        let request = VNDetectHumanBodyPoseRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
        try handler.perform([request])
        
        guard let results = request.results as? [VNHumanBodyPoseObservation], let pose = results.first else {
            throw SizingError.skeletalTrackingFailed
        }
        
        var width = Double(cgImage.width)
        var height = Double(cgImage.height)
        
        // Swap width and height if the image orientation is rotated 90 degrees (e.g. portrait photos)
        switch image.imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            swap(&width, &height)
        default:
            break
        }
        
        // Helper: Convert normalized Vision point to pixel coordinates
        func getPixelPoint(for joint: VNHumanBodyPoseObservation.JointName) -> CGPoint? {
            guard let point = try? pose.recognizedPoint(joint), point.confidence > 0.2 else { return nil }
            // Vision coordinates are normalized (0..1) with origin at bottom-left
            return CGPoint(x: point.location.x * width, y: (1.0 - point.location.y) * height)
        }
        
        func distance(_ p1: CGPoint, _ p2: CGPoint) -> Double {
            return Double(sqrt(pow(p1.x - p2.x, 2) + pow(p1.y - p2.y, 2)))
        }
        
        func ellipseCircumference(semiMajor a: Double, semiMinor b: Double) -> Double {
            return Double.pi * sqrt(2 * (pow(a, 2) + pow(b, 2)))
        }
        
        // Extract required joints for calibration and measurement
        guard let nose = getPixelPoint(for: .nose),
              let leftAnkle = getPixelPoint(for: .leftAnkle),
              let rightAnkle = getPixelPoint(for: .rightAnkle),
              let leftShoulder = getPixelPoint(for: .leftShoulder),
              let rightShoulder = getPixelPoint(for: .rightShoulder),
              let leftHip = getPixelPoint(for: .leftHip),
              let rightHip = getPixelPoint(for: .rightHip) else {
            throw SizingError.skeletalTrackingFailed
        }
        
        // Calibrate scale (cm/pixel) using vertical height
        let ankleY = (leftAnkle.y + rightAnkle.y) / 2.0
        let skeletalPixelHeight = abs(ankleY - nose.y)
        
        // Nose-to-ankle is roughly 90% of total standing height.
        let totalPixelHeight = skeletalPixelHeight / 0.90
        let k = heightCm / totalPixelHeight
        
        // Dynamic multipliers based on body type
        let chestMult: Double
        let waistMult: Double
        let hipsMult: Double
        
        switch bodyType.lowercased() {
        case "slim":
            chestMult = 1.20
            waistMult = 1.50
            hipsMult = 1.85
        case "athletic":
            chestMult = 1.28
            waistMult = 1.55
            hipsMult = 1.90
        case "curvy":
            chestMult = 1.30
            waistMult = 1.70
            hipsMult = 2.05
        default: // average
            chestMult = 1.25
            waistMult = 1.60
            hipsMult = 1.95
        }
        
        // 1. Chest Circumference
        let shoulderDist = distance(leftShoulder, rightShoulder)
        let chestWidthCm = shoulderDist * k * chestMult // Account for external muscle/fat envelope over skeletal shoulders
        let chestDepthCm = chestWidthCm * 0.70 // 0.70 is standard chest depth-to-width ratio
        let chestCircumference = ellipseCircumference(semiMajor: chestWidthCm / 2.0, semiMinor: chestDepthCm / 2.0)
        
        // 2. Waist Circumference
        let hipJointsDist = distance(leftHip, rightHip)
        let waistWidthCm = hipJointsDist * k * waistMult // Soft tissue waist width is wider than skeletal hip sockets
        let waistDepthCm = waistWidthCm * 0.75 // 0.75 is standard waist depth-to-width ratio
        let waistCircumference = ellipseCircumference(semiMajor: waistWidthCm / 2.0, semiMinor: waistDepthCm / 2.0)
        
        // 3. Hips Circumference
        let hipsWidthCm = hipJointsDist * k * hipsMult // External hips boundary is significantly wider than skeletal joints
        let hipsDepthCm = hipsWidthCm * 0.65 // 0.65 is standard hip depth-to-width ratio
        let hipsCircumference = ellipseCircumference(semiMajor: hipsWidthCm / 2.0, semiMinor: hipsDepthCm / 2.0)
        
        return [
            "chestCm": chestCircumference,
            "waistCm": waistCircumference,
            "hipsCm": hipsCircumference
        ]
    }
}

// MARK: - Errors

enum SizingError: Error {
    case missingFallbackImage
    case skeletalTrackingFailed
}
