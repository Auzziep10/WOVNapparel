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
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "FirebaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])
        }
        
        let storageRef = storage.reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
        return try await storageRef.downloadURL()
    }
    
    /// Saves the spatial sizing metrics to Firestore
    func saveMetrics(_ metrics: [String: Double], userId: String, photoURLs: [String: String]) async throws {
        let userRef = db.collection("users").document(userId)
        
        let data: [String: Any] = [
            "timestamp": FieldValue.serverTimestamp(),
            "measurements": metrics,
            "photos": photoURLs
        ]
        
        try await userRef.setData(data, merge: true)
    }
    
    /// Fetches the user profile data including measurements and remote photo URLs
    func fetchUserProfile(userId: String) async throws -> (measurements: [String: Double]?, photos: [String: String]?) {
        let snapshot = try await db.collection("users").document(userId).getDocument()
        guard let data = snapshot.data() else {
            return (nil, nil)
        }
        
        let measurements = data["measurements"] as? [String: Double]
        let photos = data["photos"] as? [String: String]
        
        return (measurements, photos)
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
}
