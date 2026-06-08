import Foundation
import Vision
import Cocoa

let screenshotPath = "/Users/catalyst2401/.gemini/antigravity/brain/ba2a6170-28ce-43cd-8fa5-5afc30312066/media__1779396938708.png"

guard let image = NSImage(contentsOfFile: screenshotPath),
      let tiffData = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiffData),
      let cgImage = bitmap.cgImage else {
    print("Failed to load CGImage from screenshot")
    exit(1)
}

// Emulate raw landscape size (let's assume it was rotated)
let rawWidth = Double(cgImage.width)
let rawHeight = Double(cgImage.height)
print("Raw Image resolution: \(rawWidth) x \(rawHeight)")

// We emulate standard portrait orientation mapping
var width = rawWidth
var height = rawHeight

// Emulate swapping for portrait orientation
let isRotated = true // standard portrait photo is rotated
if isRotated {
    swap(&width, &height)
}
print("Swapped (Oriented) resolution: \(width) x \(height)")

let request = VNDetectHumanBodyPoseRequest()
let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

do {
    try handler.perform([request])
} catch {
    print("Failed to perform Vision request: \(error)")
    exit(1)
}

guard let results = request.results as? [VNHumanBodyPoseObservation], let pose = results.first else {
    print("No body detected in the screenshot!")
    exit(1)
}

func getPixelPoint(for joint: VNHumanBodyPoseObservation.JointName) -> CGPoint? {
    guard let point = try? pose.recognizedPoint(joint), point.confidence > 0.1 else { return nil }
    return CGPoint(x: point.location.x * width, y: (1.0 - point.location.y) * height)
}

func distance(_ p1: CGPoint, _ p2: CGPoint) -> Double {
    return Double(sqrt(pow(p1.x - p2.x, 2) + pow(p1.y - p2.y, 2)))
}

func ellipseCircumference(semiMajor a: Double, semiMinor b: Double) -> Double {
    return Double.pi * sqrt(2 * (pow(a, 2) + pow(b, 2)))
}

guard let nose = getPixelPoint(for: .nose),
      let leftShoulder = getPixelPoint(for: .leftShoulder),
      let rightShoulder = getPixelPoint(for: .rightShoulder),
      let leftHip = getPixelPoint(for: .leftHip),
      let rightHip = getPixelPoint(for: .rightHip) else {
    print("Missing critical joints!")
    exit(1)
}

// Since ankles are not recognized in screenshot, we'll emulate ankle detection near the bottom (y = height * 0.95)
let leftAnkle = CGPoint(x: leftHip.x, y: height * 0.95)
let rightAnkle = CGPoint(x: rightHip.x, y: height * 0.95)

print(String(format: "Nose: (%.1f, %.1f)", nose.x, nose.y))
print(String(format: "Left Shoulder: (%.1f, %.1f)", leftShoulder.x, leftShoulder.y))
print(String(format: "Right Shoulder: (%.1f, %.1f)", rightShoulder.x, rightShoulder.y))
print(String(format: "Left Hip: (%.1f, %.1f)", leftHip.x, leftHip.y))
print(String(format: "Right Hip: (%.1f, %.1f)", rightHip.x, rightHip.y))
print(String(format: "Emulated Left Ankle: (%.1f, %.1f)", leftAnkle.x, leftAnkle.y))
print(String(format: "Emulated Right Ankle: (%.1f, %.1f)", rightAnkle.x, rightAnkle.y))

let ankleY = (leftAnkle.y + rightAnkle.y) / 2.0
let skeletalPixelHeight = abs(ankleY - nose.y)
let totalPixelHeight = skeletalPixelHeight / 0.90
let heightCm = 180.0
let k = heightCm / totalPixelHeight

print(String(format: "Skeletal Pixel Height: %.1f", skeletalPixelHeight))
print(String(format: "Total Pixel Height (Calibrated): %.1f", totalPixelHeight))
print(String(format: "Scale Factor k (cm/px): %.6f", k))

let shoulderDist = distance(leftShoulder, rightShoulder)
let chestWidthCm = shoulderDist * k
let chestDepthCm = chestWidthCm * 0.70
let chestCircumference = ellipseCircumference(semiMajor: chestWidthCm / 2.0, semiMinor: chestDepthCm / 2.0)

print(String(format: "Shoulder Dist (px): %.1f", shoulderDist))
print(String(format: "Chest Width (cm): %.2f", chestWidthCm))
print(String(format: "Chest Circumference (cm): %.2f", chestCircumference))
print(String(format: "Chest Circumference (inches): %.2f", chestCircumference / 2.54))

let hipJointsDist = distance(leftHip, rightHip)
let waistWidthCm = hipJointsDist * k * 1.05
let waistDepthCm = waistWidthCm * 0.75
let waistCircumference = ellipseCircumference(semiMajor: waistWidthCm / 2.0, semiMinor: waistDepthCm / 2.0)

print(String(format: "Hip Joints Dist (px): %.1f", hipJointsDist))
print(String(format: "Waist Circumference (cm): %.2f", waistCircumference))
print(String(format: "Waist Circumference (inches): %.2f", waistCircumference / 2.54))
