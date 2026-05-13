import SwiftUI

struct ProfileDashboardView: View {
    @EnvironmentObject var appState: AppFlowState
    
    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
            
            GeometryReader { proxy in
                Circle()
                    .fill(LinearGradient(colors: [.blue.opacity(0.1), .purple.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: proxy.size.width * 1.5)
                    .blur(radius: 60)
                    .offset(x: -proxy.size.width * 0.2, y: -proxy.size.height * 0.2)
            }
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                VStack(spacing: 8) {
                    Text("Identity Locked In")
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("Your spatial profile and reference photos are ready for hyper-realistic Virtual Try-On.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                }
                .padding(.top, 40)
                
                // Photo Grid
                HStack(spacing: 16) {
                    if let face = appState.faceImage {
                        PhotoThumbnail(image: face, label: "Face")
                    }
                    if let profile = appState.profileImage {
                        PhotoThumbnail(image: profile, label: "Profile")
                    }
                }
                .padding(.horizontal)
                
                if let body = appState.bodyImage {
                    PhotoThumbnail(image: body, label: "Full Body")
                        .frame(maxWidth: 200, maxHeight: 300)
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        appState.currentRoute = .occasionSelection
                    }
                }) {
                    Text("Start Try-On")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.8), lineWidth: 1))
                        .shadow(color: .black.opacity(0.05), radius: 15, y: 5)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.light)
    }
}

struct PhotoThumbnail: View {
    let image: UIImage
    let label: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .aspectRatio(1.0, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.5), lineWidth: 2))
                .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
            
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
    }
}
