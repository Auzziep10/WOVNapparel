import SwiftUI

struct TryOnView: View {
    @EnvironmentObject var appState: AppFlowState
    
    let occasion: String
    
    var body: some View {
        ZStack {
            Color(red: 244/255, green: 244/255, blue: 245/255).ignoresSafeArea()
            
            if let finalURL = appState.generatedImageURL {
                // Final Results
                VStack(spacing: 24) {
                    Text("Your Spatial Try-On")
                        .font(.system(size: 32, weight: .regular, design: .serif))
                        .foregroundColor(Color(red: 24/255, green: 24/255, blue: 27/255))
                        .padding(.top, 40)
                    
                    Text(occasion)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(red: 113/255, green: 113/255, blue: 122/255))
                        .textCase(.uppercase)
                        .tracking(2)
                    
                    AsyncImage(url: finalURL) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(16)
                                .shadow(color: .black.opacity(0.1), radius: 20, y: 10)
                        case .failure:
                            VStack {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 40))
                                    .foregroundColor(.red)
                                Text("Failed to load image")
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(maxHeight: 500)
                    .padding(.horizontal, 24)
                    
                    Spacer()
                    
                    Button(action: {
                        appState.currentRoute = .profileReview
                    }) {
                        Text("BACK TO DASHBOARD")
                            .font(.system(size: 12, weight: .bold))
                            .tracking(2)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.black)
                            .cornerRadius(30)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            } else {
                // Synthesizing Loading State
                VStack(spacing: 32) {
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 4)
                            .frame(width: 100, height: 100)
                        
                        Circle()
                            .trim(from: 0, to: 0.7)
                            .stroke(Color.black, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .frame(width: 100, height: 100)
                            .rotationEffect(Angle(degrees: appState.isSynthesizing ? 360 : 0))
                            .animation(.linear(duration: 1.5).repeatForever(autoreverses: false), value: appState.isSynthesizing)
                    }
                    
                    VStack(spacing: 8) {
                        Text("Synthesizing Try-On")
                            .font(.system(size: 24, weight: .regular, design: .serif))
                        
                        Text("Running AI garment mapping...")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .onAppear {
            if appState.generatedImageURL == nil {
                appState.triggerSynthesis(occasion: occasion)
            }
        }
    }
}
