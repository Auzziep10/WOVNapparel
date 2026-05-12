import SwiftUI

struct ProfileSetupView: View {
    @EnvironmentObject var appState: AppFlowState
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Create Your WOVN Profile")
                .font(.largeTitle)
                .fontWeight(.black)
                .multilineTextAlignment(.center)
            
            Text("To generate hyper-realistic virtual try-ons, we need to capture your unique identity and spatial body metrics.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(spacing: 20) {
                // Identity Capture
                Button(action: {
                    // TODO: Open Face/Profile Capture
                }) {
                    HStack {
                        Image(systemName: "face.dashed")
                            .font(.title2)
                        Text("Capture Face & Hair")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.zinc800)
                    .foregroundColor(.white)
                    .cornerRadius(16)
                }
                
                // Spatial Body Capture
                Button(action: {
                    appState.currentRoute = .captureFlow
                }) {
                    HStack {
                        Image(systemName: "figure.arms.open")
                            .font(.title2)
                        Text("Capture 3D Body Metrics")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(16)
                }
            }
            .padding(.horizontal, 30)
            
            Spacer()
        }
        .padding(.top, 60)
    }
}

extension Color {
    static let zinc800 = Color(red: 39/255, green: 39/255, blue: 42/255)
}
