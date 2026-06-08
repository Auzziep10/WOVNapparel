import SwiftUI

struct ProfileSetupView: View {
    @EnvironmentObject var appState: AppFlowState
    @AppStorage("userHeightInput") private var userHeightInput: String = ""
    @AppStorage("userBodyType") private var userBodyType: String = "Average"
    
    var body: some View {
        ZStack {
            // Minimalist Garment Catalog Background (#f4f4f5)
            Color(red: 244/255, green: 244/255, blue: 245/255).ignoresSafeArea()
            
            VStack(spacing: 40) {
                VStack(spacing: 16) {
                    Text("WOVN Profile")
                        // Playfair Display aesthetic
                        .font(.system(size: 48, weight: .regular, design: .serif))
                        .foregroundColor(Color.zinc900)
                    
                    Text("Capture your identity and spatial body metrics to generate hyper-realistic virtual try-ons.")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Color.zinc500)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .lineSpacing(4)
                }
                .padding(.top, 60)
                
                // Minimalist Input Fields
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("FULL NAME")
                            .font(.system(size: 10, weight: .semibold))
                            .tracking(1.5)
                            .foregroundColor(Color.zinc500)
                            .padding(.leading, 8)
                        
                        TextField("", text: $appState.userName)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(Color.white)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.zinc200, lineWidth: 1))
                            .foregroundColor(Color.zinc900)
                            .accentColor(Color.zinc900)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("HEIGHT")
                            .font(.system(size: 10, weight: .semibold))
                            .tracking(1.5)
                            .foregroundColor(Color.zinc500)
                            .padding(.leading, 8)
                        
                        HStack(spacing: 0) {
                            TextField("e.g. 5'10\" or 178", text: $userHeightInput)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .foregroundColor(Color.zinc900)
                                .accentColor(Color.zinc900)
                            
                            Text("in/cm")
                                .font(.system(size: 12))
                                .foregroundColor(Color.zinc400)
                                .padding(.trailing, 20)
                        }
                        .background(Color.white)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.zinc200, lineWidth: 1))
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("BODY TYPE")
                            .font(.system(size: 10, weight: .semibold))
                            .tracking(1.5)
                            .foregroundColor(Color.zinc500)
                            .padding(.leading, 8)
                        
                        HStack(spacing: 10) {
                            ForEach(["Slim", "Athletic", "Average", "Curvy"], id: \.self) { type in
                                Button(action: {
                                    userBodyType = type
                                }) {
                                    Text(type.uppercased())
                                        .font(.system(size: 10, weight: .bold))
                                        .tracking(1.0)
                                        .foregroundColor(userBodyType == type ? .white : Color.zinc900)
                                        .padding(.vertical, 12)
                                        .frame(maxWidth: .infinity)
                                        .background(userBodyType == type ? Color.zinc900 : Color.white)
                                        .clipShape(Capsule())
                                        .overlay(Capsule().stroke(userBodyType == type ? Color.zinc900 : Color.zinc200, lineWidth: 1))
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Minimalist Button
                Button(action: {
                    withAnimation {
                        appState.currentRoute = .onboardingPhotos
                    }
                }) {
                    Text("NEXT: VISUAL IDENTITY")
                        .font(.system(size: 12, weight: .semibold))
                        .tracking(2.5)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(appState.userName.isEmpty || userHeightInput.isEmpty ? Color.zinc300 : Color.zinc900)
                        .clipShape(Capsule())
                        .shadow(color: (appState.userName.isEmpty || userHeightInput.isEmpty) ? .clear : Color.black.opacity(0.12), radius: 10, y: 5)
                }
                .disabled(appState.userName.isEmpty || userHeightInput.isEmpty)
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.light)
    }
}

extension Color {
    static let zinc900 = Color(red: 24/255, green: 24/255, blue: 27/255)
    static let zinc800 = Color(red: 39/255, green: 39/255, blue: 42/255)
    static let zinc500 = Color(red: 113/255, green: 113/255, blue: 122/255)
    static let zinc400 = Color(red: 161/255, green: 161/255, blue: 170/255)
    static let zinc300 = Color(red: 212/255, green: 212/255, blue: 216/255)
    static let zinc200 = Color(red: 228/255, green: 228/255, blue: 231/255)
}
