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
    
    /// Saves the spatial sizing metrics and name to Firestore
    func saveMetrics(_ metrics: [String: Double], userId: String, photoURLs: [String: String], name: String) async throws {
        let userRef = db.collection("users").document(userId)
        
        let data: [String: Any] = [
            "timestamp": FieldValue.serverTimestamp(),
            "name": name,
            "measurements": metrics,
            "photos": photoURLs
        ]
        
        try await userRef.setData(data, merge: true)
    }
    
    /// Fetches the user profile data including name, measurements and remote photo URLs
    func fetchUserProfile(userId: String) async throws -> (name: String?, measurements: [String: Double]?, photos: [String: String]?) {
        let snapshot = try await db.collection("users").document(userId).getDocument()
        guard let data = snapshot.data() else {
            return (nil, nil, nil)
        }
        
        let name = data["name"] as? String
        let measurements = data["measurements"] as? [String: Double]
        let photos = data["photos"] as? [String: String]
        
        return (name, measurements, photos)
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
    
    /// Calculates standard Euclidean color distance in CIELAB space
    private func calculateDeltaE(lab1: [Double], lab2: [Double]) -> Double {
        let dl = lab1[0] - lab2[0]
        let da = lab1[1] - lab2[1]
        let db = lab1[2] - lab2[2]
        return sqrt(dl*dl + da*da + db*db)
    }
    
    /// Fetches available garments from Tech Packs based on occasion and automatically filters them against user's skin LAB profile
    func fetchGarments(for occasion: String, skinLAB: [Double]? = nil) async throws -> [Garment] {
        // We do a lowercase match to make it more robust, but Firestore requires exact matches or text search.
        // Assuming occasion is passed exactly as stored.
        let snapshot = try await db.collection("tech_packs")
            .whereField("occasion", isEqualTo: occasion)
            .getDocuments()
            
        var garments: [Garment] = []
        for doc in snapshot.documents {
            let data = doc.data()
            // We use the doc ID as the Garment ID so we can pass it to the synthesis backend
            let garmentId = doc.documentID
            let type = data["garmentType"] as? String ?? "unknown"
            
            // Extract all colorways from the new Tech Pack Creator extraction flow
            var addedColorways = false
            if let colorways = data["dominantColorways"] as? [[String: Any]] {
                for (index, cw) in colorways.enumerated() {
                    if let cwImage = cw["image"] as? String, !cwImage.isEmpty {
                        
                        // --- Personal Stylist Color Filtering Algorithm ---
                        if let userSkin = skinLAB, let garmentLab = cw["lab"] as? [Double], garmentLab.count == 3 {
                            let distance = calculateDeltaE(lab1: userSkin, lab2: garmentLab)
                            
                            // Rejection Rule: If Delta E < 25, the color is too close to the user's skin tone (naked/washed out effect).
                            // We completely ignore this colorway!
                            if distance < 25.0 {
                                print("Stylist: Rejected colorway \(index) (Delta E: \(distance)) - Too close to skin tone!")
                                continue
                            } else {
                                print("Stylist: Approved colorway \(index) (Delta E: \(distance))")
                            }
                        }
                        // --------------------------------------------------
                        
                        // Append EACH approved colorway as its own selectable garment in the Rolodex!
                        // We append the index to the ID so SwiftUI ForEach doesn't crash from duplicate IDs.
                        garments.append(Garment(id: "\(garmentId)_cw_\(index)", type: type, thumbnail: cwImage))
                        addedColorways = true
                    }
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
