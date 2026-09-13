import Foundation
import UIKit
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

class FirebaseManager {
    static let shared = FirebaseManager()
    
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    private init() {}
    
    /// Signs up a new user with email and password
    func signUp(email: String, password: String) async throws -> String {
        let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
        return authResult.user.uid
    }
    
    /// Signs in an existing user with email and password
    func signIn(email: String, password: String) async throws -> String {
        let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
        return authResult.user.uid
    }
    
    /// Uploads an identity image to Firebase Storage and returns the download URL.
    func uploadImage(_ image: UIImage, path: String) async throws -> URL {
        let normalizedImage = image.fixOrientation()
        guard let imageData = normalizedImage.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "FirebaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])
        }
        
        let storageRef = storage.reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
        return try await storageRef.downloadURL()
    }
    
    /// Saves the spatial sizing metrics, name, and gender to Firestore
    func saveMetrics(_ metrics: [String: Double], userId: String, photoURLs: [String: String], name: String, gender: String? = nil) async throws {
        let userRef = db.collection("users").document(userId)
        
        var data: [String: Any] = [
            "timestamp": FieldValue.serverTimestamp(),
            "name": name,
            "measurements": metrics,
            "photos": photoURLs
        ]
        if let g = gender {
            data["gender"] = g
        }
        
        try await userRef.setData(data, merge: true)
    }
    
    /// Fetches the user profile data including name, measurements, remote photo URLs, and gender
    func fetchUserProfile(userId: String) async throws -> (name: String?, measurements: [String: Double]?, photos: [String: String]?, gender: String?) {
        let snapshot = try await db.collection("users").document(userId).getDocument()
        guard let data = snapshot.data() else {
            return (nil, nil, nil, nil)
        }
        
        let name = data["name"] as? String
        let measurements = data["measurements"] as? [String: Double]
        let photos = data["photos"] as? [String: String]
        let gender = data["gender"] as? String
        
        return (name, measurements, photos, gender)
    }
    
    /// Fetches the list of saved AI Try-On URLs for the user
    func fetchUserRenders(userId: String) async throws -> [SavedRender] {
        let snapshot = try await db.collection("users").document(userId).collection("renders")
            .order(by: "timestamp", descending: true)
            .getDocuments()
            
        var renders: [SavedRender] = []
        for doc in snapshot.documents {
            let data = doc.data()
            if let url = data["url"] as? String {
                let garmentId = data["garmentId"] as? String ?? "DEFAULT"
                let occasion = data["occasion"] as? String ?? "Unknown"
                
                let render = SavedRender(
                    id: doc.documentID,
                    url: url,
                    garmentId: garmentId,
                    occasion: occasion
                )
                renders.append(render)
            }
        }
        return renders
    }
    
    /// Saves a newly generated AI Try-On render URL to the user's collection in Firestore
    func saveUserRender(userId: String, url: String, garmentId: String, occasion: String) async throws -> String {
        let docRef = try await db.collection("users").document(userId).collection("renders").addDocument(data: [
            "url": url,
            "garmentId": garmentId,
            "occasion": occasion,
            "timestamp": FieldValue.serverTimestamp()
        ])
        return docRef.documentID
    }
    
    /// Converts a hex color string (e.g. "#D0C9B6") to a CIELAB [Double] value
    private func hexToLab(_ hex: String) -> [Double]? {
        var cleanHex = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if cleanHex.hasPrefix("#") {
            cleanHex.remove(at: cleanHex.startIndex)
        }
        
        guard cleanHex.count == 6 else { return nil }
        
        var rgbValue: UInt64 = 0
        Scanner(string: cleanHex).scanHexInt64(&rgbValue)
        
        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0
        
        // Convert to linear sRGB
        let rL = r > 0.04045 ? pow((r + 0.055) / 1.055, 2.4) : r / 12.92
        let gL = g > 0.04045 ? pow((g + 0.055) / 1.055, 2.4) : g / 12.92
        let bL = b > 0.04045 ? pow((b + 0.055) / 1.055, 2.4) : b / 12.92
        
        // Convert to XYZ (D65 white point)
        let x = rL * 0.4124 + gL * 0.3576 + bL * 0.1805
        let y = rL * 0.2126 + gL * 0.7152 + bL * 0.0722
        let z = rL * 0.0193 + gL * 0.1192 + bL * 0.9505
        
        // Normalize for D65
        let xN = x / 0.95047
        let yN = y / 1.00000
        let zN = z / 1.08883
        
        let fx = xN > 0.008856 ? pow(xN, 1.0/3.0) : (7.787 * xN) + (16.0 / 116.0)
        let fy = yN > 0.008856 ? pow(yN, 1.0/3.0) : (7.787 * yN) + (16.0 / 116.0)
        let fz = zN > 0.008856 ? pow(zN, 1.0/3.0) : (7.787 * zN) + (16.0 / 116.0)
        
        let l = (116.0 * fy) - 16.0
        let a = 500.0 * (fx - fy)
        let labB = 200.0 * (fy - fz)
        
        return [l, a, labB]
    }
    
    /// Calculates standard Euclidean color distance in CIELAB space
    private func calculateDeltaE(lab1: [Double], lab2: [Double]) -> Double {
        let dl = lab1[0] - lab2[0]
        let da = lab1[1] - lab2[1]
        let db = lab1[2] - lab2[2]
        return sqrt(dl*dl + da*da + db*db)
    }
    
    /// Checks if a garment audience string matches the user's selected gender
    private func matchesGender(garmentAudience: String, userGender: String) -> Bool {
        let g = garmentAudience.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let u = userGender.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if u.isEmpty || u == "all" || u == "unisex" { return true }
        if g.isEmpty || g == "unisex" || g == "all" { return true }
        
        let isUserMale = (u.contains("men") && !u.contains("women")) || (u.contains("male") && !u.contains("female"))
        let isUserFemale = u.contains("women") || u.contains("female")
        
        let isGarmentMale = (g.contains("men") && !g.contains("women")) || (g.contains("male") && !g.contains("female"))
        let isGarmentFemale = g.contains("women") || g.contains("female")
        
        if isUserMale {
            return isGarmentMale
        } else if isUserFemale {
            return isGarmentFemale
        }
        return true
    }
    
    /// Fetches available garments from Tech Packs based on occasion and automatically filters & ranks them to the top 5 color options matching user's skin tone to hair color ratio
    func fetchGarments(for occasion: String, skinLAB: [Double]? = nil, contrastIndex: Double? = nil, gender: String? = nil) async throws -> [Garment] {
        // We do a lowercase match to make it more robust, but Firestore requires exact matches or text search.
        // Assuming occasion is passed exactly as stored.
        var snapshot = try await db.collection("tech_packs")
            .whereField("occasion", isEqualTo: occasion)
            .getDocuments()
            
        if snapshot.documents.isEmpty && occasion == "Daily" {
            snapshot = try await db.collection("tech_packs")
                .whereField("occasion", isEqualTo: "Everyday")
                .getDocuments()
        }
            
        var garments: [Garment] = []
        for doc in snapshot.documents {
            let data = doc.data()
            
            // Gender filtering: skip garment if audience/gender conflicts with user gender
            if let userGender = gender, !userGender.isEmpty {
                let garmentAudience = (data["gender"] as? String ?? data["audience"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                if !garmentAudience.isEmpty && !matchesGender(garmentAudience: garmentAudience, userGender: userGender) {
                    print("Stylist: Filtered out \(doc.documentID) ('\(garmentAudience)') for user gender '\(userGender)'")
                    continue
                }
            }
            
            // We use the doc ID as the Garment ID so we can pass it to the synthesis backend
            let garmentId = doc.documentID
            let type = data["garmentType"] as? String ?? "unknown"
            
            // Extract all colorways from the Tech Pack and rank against skin-to-hair ratio
            var addedColorways = false
            if let colorways = data["dominantColorways"] as? [[String: Any]], !colorways.isEmpty {
                var candidateColorways: [(index: Int, garment: Garment, score: Double)] = []
                
                for (index, cw) in colorways.enumerated() {
                    guard let cwImage = cw["image"] as? String, !cwImage.isEmpty else { continue }
                    
                    var garmentLab: [Double]? = nil
                    // 1. Prefer precise calculation from Hex color if available
                    if let hexString = cw["hex"] as? String, let calculatedLab = hexToLab(hexString) {
                        garmentLab = calculatedLab
                    } else if let labArray = cw["lab"] as? [Any] {
                        // 2. Robust fallback parsing of the Firestore 'lab' array
                        let parsed = labArray.compactMap { ($0 as? NSNumber)?.doubleValue ?? ($0 as? Double) ?? ($0 as? Int).map(Double.init) }
                        if parsed.count == 3 {
                            garmentLab = parsed
                        }
                    }
                    
                    var score: Double = 50.0
                    
                    // --- Personal Stylist Color Matching Algorithm ---
                    if let userSkin = skinLAB, let gLab = garmentLab {
                        let distance = calculateDeltaE(lab1: userSkin, lab2: gLab)
                        
                        // Rejection Rule: If Delta E < 22.0, the color is too close to the user's skin tone (naked/washed out effect).
                        if distance < 22.0 {
                            print("Stylist: Rejected colorway \(index) (\(cw["name"] as? String ?? "")) (Delta E: \(distance)) - Too close to skin tone!")
                            continue
                        }
                        
                        let deltaL = abs(gLab[0] - userSkin[0]) // Luminance contrast between garment and skin
                        let userContrast = contrastIndex ?? 50.0 // Skin tone to hair color ratio (0-100)
                        
                        // Contrast Harmony: Match garment's contrast with user's skin-to-hair contrast ratio
                        let contrastMatch = 100.0 - abs(deltaL - userContrast)
                        score = contrastMatch
                        
                        // Distinct separation bonus
                        if distance >= 35.0 {
                            score += 15.0
                        }
                        
                        // Undertone harmony bonus
                        let skinB = userSkin[2]
                        let garmentB = gLab[2]
                        if skinB > 12.0 && garmentB > 0 {
                            score += 10.0 // Warm skin + warm colorway
                        } else if skinB <= 12.0 && garmentB <= 2.0 {
                            score += 10.0 // Cool skin + cool colorway
                        }
                    } else if let userContrast = contrastIndex, let gLab = garmentLab {
                        let targetLuma = userContrast > 50.0 ? 25.0 : 55.0
                        score = 100.0 - abs(gLab[0] - targetLuma)
                    }
                    
                    let item = Garment(id: "\(garmentId)_cw_\(index)", type: type, thumbnail: cwImage)
                    candidateColorways.append((index: index, garment: item, score: score))
                }
                
                // Select only the TOP 5 matching color options based on skin tone to hair color ratio
                let topColorways = candidateColorways
                    .sorted(by: { $0.score > $1.score })
                    .prefix(5)
                
                for candidate in topColorways {
                    garments.append(candidate.garment)
                    addedColorways = true
                    print("Stylist: Selected Top Colorway #\(candidate.index) (\(candidate.garment.id)) with Match Score: \(String(format: "%.1f", candidate.score))")
                }
            }
            
            // If the tech pack doesn't have individual colorway images, fallback to the main render
            if !addedColorways {
                if let thumbnailUrl = data["renderUrl"] as? String, !thumbnailUrl.isEmpty {
                    garments.append(Garment(id: garmentId, type: type, thumbnail: thumbnailUrl))
                }
            }
        }
        return garments
    }
}

extension UIImage {
    func fixOrientation() -> UIImage {
        if self.imageOrientation == .up {
            return self
        }
        
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        self.draw(in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return normalizedImage ?? self
    }
}
