import SwiftUI

struct ProfileDashboardView: View {
    @EnvironmentObject var appState: AppFlowState
    
    var body: some View {
        ZStack {
            Color(red: 244/255, green: 244/255, blue: 245/255).ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 40) {
                        
                        // HEADER
                        VStack(spacing: 12) {
                            Text("Identity Captured")
                                .font(.system(size: 36, weight: .regular, design: .serif))
                                .foregroundColor(Color(red: 24/255, green: 24/255, blue: 27/255))
                            
                            Text("Your spatial profile and reference photos are securely locked in and ready for Virtual Try-On.")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(Color(red: 113/255, green: 113/255, blue: 122/255))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                                .lineSpacing(4)
                        }
                        .padding(.top, 40)
                        
                        // AVATAR ROW (Face & Profile)
                        HStack(spacing: 40) {
                            if let face = appState.faceImage {
                                AvatarThumbnail(image: face, label: "FACE", rotate180: true)
                            }
                            if let profile = appState.profileImage {
                                AvatarThumbnail(image: profile, label: "PROFILE", rotate180: true)
                            }
                        }
                        
                        // HERO IMAGE (Full Body)
                        if let bodyImage = appState.bodyImage {
                            HeroPhotoThumbnail(image: bodyImage, label: "FULL BODY")
                        }
                        
                        Spacer(minLength: 40)
                    }
                }
                
                // BOTTOM ACTION BAR
                VStack {
                    Divider()
                    Button(action: {
                        withAnimation {
                            appState.currentRoute = .occasionSelection
                        }
                    }) {
                        Text("START TRY-ON")
                            .font(.system(size: 12, weight: .bold))
                            .tracking(2)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(Color(red: 24/255, green: 24/255, blue: 27/255))
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                }
                .background(Color(red: 250/255, green: 250/255, blue: 250/255).ignoresSafeArea(edges: .bottom))
            }
        }
        .preferredColorScheme(.light)
    }
}

struct AvatarThumbnail: View {
    let image: UIImage
    let label: String
    let rotate180: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 100, height: 100)
                .rotationEffect(rotate180 ? .degrees(180) : .zero)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color(red: 228/255, green: 228/255, blue: 231/255), lineWidth: 1))
                .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
            
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .tracking(1.5)
                .foregroundColor(Color(red: 161/255, green: 161/255, blue: 170/255))
        }
    }
}

struct HeroPhotoThumbnail: View {
    let image: UIImage
    let label: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: UIScreen.main.bounds.width - 48, maxHeight: 450)
                .clipShape(RoundedRectangle(cornerRadius: 0)) // Sharp corners for editorial look
                .overlay(RoundedRectangle(cornerRadius: 0).stroke(Color(red: 228/255, green: 228/255, blue: 231/255), lineWidth: 1))
                .shadow(color: .black.opacity(0.08), radius: 20, y: 10)
            
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .tracking(1.5)
                .foregroundColor(Color(red: 161/255, green: 161/255, blue: 170/255))
        }
    }
}
