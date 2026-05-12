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
            case .captureFlow:
                CameraView()
            case .tryOn(let techPackId):
                Text("Try-On View for \(techPackId)")
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: appState.currentRoute)
    }
}

#Preview {
    ContentView()
}
