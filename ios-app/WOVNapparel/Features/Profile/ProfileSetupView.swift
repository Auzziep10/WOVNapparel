import SwiftUI

struct ProfileSetupView: View {
    @EnvironmentObject var appState: AppFlowState
    @AppStorage("userHeightInput") private var userHeightInput: String = ""
    
    var body: some View {
        ZStack {
            // Sleek animated background to make the glass visible
            Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
            
            GeometryReader { proxy in
                Circle()
                    .fill(LinearGradient(colors: [.blue.opacity(0.3), .purple.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: proxy.size.width * 1.5)
                    .blur(radius: 60)
                    .offset(x: -proxy.size.width * 0.2, y: -proxy.size.height * 0.2)
            }
            .ignoresSafeArea()
            
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
                
                // Basic Info Input (Liquid Glass)
                VStack(spacing: 16) {
                    TextField("Full Name", text: $appState.userName)
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.5), lineWidth: 1))
                        .foregroundColor(.primary)
                        .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
                    
                    HStack {
                        TextField("Height (e.g. 5'10\" or 178)", text: $userHeightInput)
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(16)
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.5), lineWidth: 1))
                            .foregroundColor(.primary)
                            .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
                        
                        Text("in/cm")
                            .foregroundColor(.secondary)
                            .padding(.trailing, 10)
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Next Step (Liquid Glass)
                Button(action: {
                    withAnimation {
                        appState.currentRoute = .onboardingPhotos
                    }
                }) {
                    Text("Next: Visual Identity")
                        .font(.headline)
                        .foregroundColor(appState.userName.isEmpty || userHeightInput.isEmpty ? .secondary : .primary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.8), lineWidth: 1))
                        .shadow(color: .black.opacity(0.05), radius: 15, y: 5)
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
