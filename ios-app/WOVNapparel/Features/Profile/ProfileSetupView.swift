import SwiftUI

struct ProfileSetupView: View {
    @EnvironmentObject var appState: AppFlowState
    @AppStorage("userHeightInput") private var userHeightInput: String = ""
    
    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
            
            VStack(spacing: 30) {
                VStack(spacing: 8) {
                    Text("WOVN Profile")
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("Capture your identity and spatial body metrics to generate hyper-realistic virtual try-ons.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                }
                .padding(.top, 40)
                
                // Basic Info Input
                VStack(spacing: 16) {
                    TextField("Full Name", text: $appState.userName)
                        .padding()
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .cornerRadius(12)
                        .foregroundColor(.primary)
                        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
                    
                    HStack {
                        TextField("Height (e.g. 5'10\" or 178)", text: $userHeightInput)
                            .padding()
                            .background(Color(uiColor: .secondarySystemGroupedBackground))
                            .cornerRadius(12)
                            .foregroundColor(.primary)
                            .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
                        
                        Text("in/cm")
                            .foregroundColor(.secondary)
                            .padding(.trailing, 10)
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Next Step
                Button(action: {
                    withAnimation {
                        appState.currentRoute = .onboardingPhotos
                    }
                }) {
                    Text("Next: Visual Identity")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(appState.userName.isEmpty || userHeightInput.isEmpty ? Color.blue.opacity(0.5) : Color.blue)
                        .cornerRadius(16)
                        .shadow(color: .blue.opacity(0.3), radius: 10, y: 5)
                }
                .disabled(appState.userName.isEmpty || userHeightInput.isEmpty)
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.light)
    }
}

extension Color {
    static let zinc800 = Color(red: 39/255, green: 39/255, blue: 42/255)
}
