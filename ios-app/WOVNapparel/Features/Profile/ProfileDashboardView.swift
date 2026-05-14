import SwiftUI

struct ProfileDashboardView: View {
    @EnvironmentObject var appState: AppFlowState
    
    var body: some View {
        ZStack {
            // Minimalist Garment Catalog Background
            Color(red: 244/255, green: 244/255, blue: 245/255).ignoresSafeArea()
            
            VStack(spacing: 30) {
                VStack(spacing: 8) {
                    Text("Identity Locked In")
                        .font(.system(size: 36, weight: .regular, design: .serif))
                        .foregroundColor(Color(red: 24/255, green: 24/255, blue: 27/255))
                    
                    Text("Your spatial profile and reference photos are ready for hyper-realistic Virtual Try-On.")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Color(red: 113/255, green: 113/255, blue: 122/255))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .lineSpacing(4)
                }
                .padding(.top, 40)
                
                // Photo Grid
                HStack(spacing: 16) {
                    if let face = appState.faceImage {
                        PhotoThumbnail(image: face, label: "FACE", rotate180: true)
                    }
                    if let profile = appState.profileImage {
                        PhotoThumbnail(image: profile, label: "PROFILE", rotate180: true)
                    }
                }
                .padding(.horizontal, 24)
                
                if let body = appState.bodyImage {
                    PhotoThumbnail(image: body, label: "FULL BODY", rotate180: false)
                        .frame(maxWidth: 250, maxHeight: 350)
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        appState.currentRoute = .occasionSelection
                    }
                }) {
                    Text("START TRY-ON")
                        .font(.system(size: 12, weight: .semibold))
                        .tracking(2)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color(red: 24/255, green: 24/255, blue: 27/255))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.light)
    }
}

struct PhotoThumbnail: View {
    let image: UIImage
    let label: String
    let rotate180: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .aspectRatio(1.0, contentMode: .fit)
                .rotationEffect(rotate180 ? .degrees(180) : .zero) // Fix ARKit upside down
                .clipShape(RoundedRectangle(cornerRadius: 8)) // Slight curve for photos
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(red: 228/255, green: 228/255, blue: 231/255), lineWidth: 1))
            
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.5)
                .foregroundColor(Color(red: 113/255, green: 113/255, blue: 122/255))
        }
    }
}
