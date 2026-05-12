import SwiftUI

struct OccasionDashboard: View {
    @EnvironmentObject var appState: AppFlowState
    
    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
            
            VStack {
                Text("Occasions")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Select an occasion to browse curated tech packs.")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding()
        }
        .preferredColorScheme(.light)
    }
}
