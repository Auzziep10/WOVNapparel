import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppFlowState
    
    var body: some View {
        Group {
            if !appState.isAuthenticated {
                AuthenticationView()
            } else {
                switch appState.currentRoute {
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
