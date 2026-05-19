import UIKit
import Vision
import CoreImage

class ChromaticAnalyzer {
    
    /// Analyzes the user's face image to calculate a Chromatic Contrast Index.
    /// This index helps determine the best garment color (e.g. high contrast vs low contrast palettes).
    /// Returns a value between 0 and 100.
    static func analyzeContrast(image: UIImage) async -> Double {
        guard let cgImage = image.cgImage else { return 50.0 } // Default
        
        return await withCheckedContinuation { continuation in
            let request = VNDetectFaceLandmarksRequest { request, error in
                guard let results = request.results as? [VNFaceObservation],
                      let face = results.first,
                      let landmarks = face.landmarks else {
                    continuation.resume(returning: 50.0)
                    return
                }
                
                // Get bounding boxes for Face and Hair/Forehead
                let boundingBox = face.boundingBox
                let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
                
                // Convert Vision boundingBox (normalized, origin at bottom-left) to Image Coordinates
                let faceRect = VNImageRectForNormalizedRect(boundingBox, Int(imageSize.width), Int(imageSize.height))
                
                // Estimate skin region (cheeks)
                let cheekRect = CGRect(
                    x: faceRect.origin.x + faceRect.width * 0.2,
                    y: faceRect.origin.y + faceRect.height * 0.4,
                    width: faceRect.width * 0.2,
                    height: faceRect.height * 0.2
                )
                
                // Estimate hair/forehead region (top of face bounding box)
                let hairRect = CGRect(
                    x: faceRect.origin.x + faceRect.width * 0.3,
                    y: faceRect.origin.y + faceRect.height * 0.85,
                    width: faceRect.width * 0.4,
                    height: faceRect.height * 0.15
                )
                
                // Sample colors
                let skinColor = averageColor(of: cgImage, in: cheekRect)
                let hairColor = averageColor(of: cgImage, in: hairRect)
                
                // Calculate Luma (Luminance) difference as Contrast Index
                let skinLuma = luma(for: skinColor)
                let hairLuma = luma(for: hairColor)
                
                // Contrast index is a magnitude difference between 0 and 100
                // High contrast (e.g. pale skin, dark hair) will be ~ 70+
                // Low contrast (e.g. dark skin, dark hair) will be ~ 20-40
                let contrast = abs(skinLuma - hairLuma) * 100
                
                print("ChromaticAnalyzer - Skin Luma: \(skinLuma), Hair Luma: \(hairLuma), Contrast Index: \(contrast)")
                
                continuation.resume(returning: min(max(contrast, 0), 100))
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up)
            do {
                try handler.perform([request])
            } catch {
                print("Vision error: \(error)")
                continuation.resume(returning: 50.0)
            }
        }
    }
    
    private static func averageColor(of image: CGImage, in rect: CGRect) -> UIColor {
        // Ensure rect is within image bounds
        let safeRect = rect.intersection(CGRect(x: 0, y: 0, width: image.width, height: image.height))
        guard safeRect.width > 0 && safeRect.height > 0,
              let croppedImage = image.cropping(to: safeRect) else {
            return .gray
        }
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var bitmapData = [UInt8](repeating: 0, count: 4)
        
        let context = CGContext(
            data: &bitmapData,
            width: 1,
            height: 1,
            bitsPerComponent: 8,
            bytesPerRow: 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        )
        
        context?.draw(croppedImage, in: CGRect(x: 0, y: 0, width: 1, height: 1))
        
        let r = CGFloat(bitmapData[0]) / 255.0
        let g = CGFloat(bitmapData[1]) / 255.0
        let b = CGFloat(bitmapData[2]) / 255.0
        let a = CGFloat(bitmapData[3]) / 255.0
        
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
    
    private static func luma(for color: UIColor) -> Double {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        // Standard RGB Luma formula
        return Double((0.299 * r) + (0.587 * g) + (0.114 * b))
    }
}
