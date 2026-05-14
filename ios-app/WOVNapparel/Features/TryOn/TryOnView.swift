import SwiftUI

struct TryOnView: View {
    @EnvironmentObject var appState: AppFlowState
    
    let occasion: String
    
    var body: some View {
        ZStack {
            // 1. Full-Bleed Background Layer
            if let finalURL = appState.generatedImageURL {
                AsyncImage(url: finalURL) { phase in
                    switch phase {
                    case .empty:
                        Color(red: 244/255, green: 244/255, blue: 245/255).ignoresSafeArea()
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .ignoresSafeArea()
                            // Slight dimming if synthesizing a new garment so the user knows it's working
                            .opacity(appState.isSynthesizing ? 0.6 : 1.0)
                            .animation(.easeInOut, value: appState.isSynthesizing)
                    case .failure:
                        Color(red: 244/255, green: 244/255, blue: 245/255).ignoresSafeArea()
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                Color(red: 244/255, green: 244/255, blue: 245/255).ignoresSafeArea()
            }
            
            // 2. Global Loading Spinner (Only for initial load)
            if appState.generatedImageURL == nil && appState.isSynthesizing {
                VStack(spacing: 32) {
                    Text("\(appState.synthesisProgress)%")
                        .font(.system(size: 64, weight: .light, design: .serif))
                        .foregroundColor(Color(red: 24/255, green: 24/255, blue: 27/255))
                    
                    VStack(spacing: 8) {
                        Text("Synthesizing Style...")
                            .font(.system(size: 24, weight: .regular, design: .serif))
                        
                        Text("Running AI garment mapping...")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                }
            }
            
            // 3. UI Overlay
            if appState.generatedImageURL != nil {
                VStack {
                    // Top Logo
                    HStack {
                        Image("wovn-logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100)
                            .colorMultiply(.black) // Force black if needed, or leave native
                        Spacer()
                    }
                    .padding(.leading, 24)
                    .padding(.top, 20)
                    
                    Spacer()
                    
                    // Left Rolodex Menu
                    HStack {
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: 20) {
                                ForEach(appState.recommendedGarments) { garment in
                                    Button(action: {
                                        // Only trigger if we aren't already synthesizing this exact garment
                                        if appState.selectedGarmentId != garment.id && !appState.isSynthesizing {
                                            let generator = UIImpactFeedbackGenerator(style: .medium)
                                            generator.impactOccurred()
                                            appState.triggerSynthesis(occasion: occasion, garmentId: garment.id)
                                        }
                                    }) {
                                        ZStack {
                                            Circle()
                                                .fill(Color.white)
                                                .frame(width: 60, height: 60)
                                                .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
                                            
                                            AsyncImage(url: URL(string: garment.thumbnail)) { image in
                                                image.resizable().scaledToFill()
                                            } placeholder: {
                                                Color.gray.opacity(0.2)
                                            }
                                            .frame(width: 50, height: 50)
                                            .clipShape(Circle())
                                            
                                            // Show percentage ON the bubble if this specific one is loading
                                            if appState.isSynthesizing && appState.selectedGarmentId == garment.id {
                                                Circle()
                                                    .fill(Color.black.opacity(0.6))
                                                    .frame(width: 60, height: 60)
                                                
                                                Text("\(appState.synthesisProgress)%")
                                                    .font(.system(size: 14, weight: .bold))
                                                    .foregroundColor(.white)
                                            }
                                            
                                            // Selection Ring
                                            if appState.selectedGarmentId == garment.id {
                                                Circle()
                                                    .stroke(Color.black, lineWidth: 2)
                                                    .frame(width: 66, height: 66)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 40)
                            .padding(.leading, 24)
                        }
                        .frame(width: 100)
                        
                        Spacer()
                    }
                    
                    Spacer()
                    
                    // Bottom Done Button
                    Button(action: {
                        appState.currentRoute = .profileReview
                    }) {
                        Text("SAVE & EXIT")
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
            }
        }
        .onAppear {
            if appState.generatedImageURL == nil {
                appState.triggerSynthesis(occasion: occasion)
            }
        }
    }
}
