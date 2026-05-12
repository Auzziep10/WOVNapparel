import SwiftUI

struct OccasionDashboard: View {
    @EnvironmentObject var appState: AppFlowState
    
    var body: some View {
        VStack {
            Text("Occasions")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Select an occasion to browse curated tech packs.")
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
    }
}
