import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppFlowState
    
    var body: some View {
        Group {
            switch appState.currentRoute {
            case .onboarding:
                ProfileSetupView()
            case .dashboard:
                OccasionDashboard()
            case .lidarCaptureFlow:
                if #available(iOS 14.0, *) {
                    ARScannerView()
                } else {
                    Text("LiDAR requires iOS 14+")
                }
            case .standardCaptureFlow:
                CameraView()
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
