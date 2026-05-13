import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppFlowState
    
    var body: some View {
        Group {
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
                OccasionSelectionView()
            case .tryOn(let techPackId):
                Text("Try-On View for \(techPackId)")
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: appState.currentRoute)
        .preferredColorScheme(.light)
    }
}

#Preview {
    ContentView()
}
