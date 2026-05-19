import SwiftUI

struct TryOnDetailView: View {
    @EnvironmentObject var appState: AppFlowState
    
    let render: SavedRender
    @State private var recommendedSize: String = "Calculating..."
    
    var body: some View {
        ZStack {
            // Full-bleed image background
            GeometryReader { geo in
                AsyncImage(url: URL(string: render.url)) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: geo.size.width, height: geo.size.height)
                            .clipped()
                    } else {
                        Color(red: 244/255, green: 244/255, blue: 245/255)
                            .overlay(ProgressView())
                    }
                }
            }
            .ignoresSafeArea()
            
            // Top Nav
            VStack {
                HStack {
                    Button(action: {
                        appState.currentRoute = .gallery
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.black)
                            .padding(12)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                Spacer()
                
                // Recommended Size Overlay Pill
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(.black)
                    
                    Text(recommendedSize)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.black)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
                .padding(.bottom, 48)
            }
        }
        .task {
            // Trigger the network call to Vercel API
            do {
                recommendedSize = try await appState.fetchSizeRecommendation(techPackId: render.garmentId)
            } catch {
                recommendedSize = "Size: Unknown"
            }
        }
    }
}
