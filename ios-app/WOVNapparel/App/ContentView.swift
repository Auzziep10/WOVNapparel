import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppFlowState
    
    var body: some View {
        Group {
            if !appState.isAuthenticated {
                AuthenticationView()
            } else {
                switch appState.currentRoute {
                case .loading:
                    VStack(spacing: 24) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .black))
                            .scaleEffect(1.5)
                        Text("Syncing Profile...")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(red: 244/255, green: 244/255, blue: 245/255).ignoresSafeArea())
                case .onboardingBasic:
                    ProfileSetupView()
                case .onboardingPhotos:
                    IdentityCaptureView()
                case .lidarCaptureFlow:
                    if #available(iOS 17.0, *) {
                        ARScannerView()
                    } else {
                        Text("3D Scanning requires iOS 17+")
                    }
                case .standardCaptureFlow:
                    CameraView()
                case .profileReview:
                    ProfileDashboardView()
                case .occasionSelection:
                    if #available(iOS 17.0, *) {
                        OccasionSelectionView()
                    } else {
                        Text("Occasion Selection requires iOS 17")
                    }
                case .tryOn(let techPackId):
                    TryOnView(occasion: techPackId)
                case .gallery:
                    TryOnGalleryView()
                case .tryOnDetail(let render):
                    TryOnDetailView(render: render)
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: appState.currentRoute)
        .animation(.easeInOut, value: appState.isAuthenticated)
        .preferredColorScheme(.light)
    }
}

#Preview {
    ContentView()
}
