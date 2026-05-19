import SwiftUI

struct TryOnGalleryView: View {
    @EnvironmentObject var appState: AppFlowState
    
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        ZStack(alignment: .top) {
            Color(red: 244/255, green: 244/255, blue: 245/255).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        appState.currentRoute = .profileReview
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.black)
                            .padding(12)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
                    }
                    
                    Spacer()
                    
                    Text("Past Try-Ons")
                        .font(.system(size: 20, weight: .regular, design: .serif))
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    // Invisible view for centering
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 24)
                
                if appState.savedTryOns.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "photo.stack")
                            .font(.system(size: 48))
                            .foregroundColor(Color(red: 212/255, green: 212/255, blue: 216/255))
                        Text("No try-ons yet")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray)
                        Spacer()
                    }
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(appState.savedTryOns) { render in
                                Button(action: {
                                    appState.currentRoute = .tryOnDetail(render: render)
                                }) {
                                    AsyncImage(url: URL(string: render.url)) { phase in
                                        if let image = phase.image {
                                            image
                                                .resizable()
                                                .scaledToFill()
                                                .frame(minWidth: 0, maxWidth: .infinity)
                                                .aspectRatio(3/4, contentMode: .fit)
                                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                                .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
                                        } else {
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(Color(red: 228/255, green: 228/255, blue: 231/255))
                                                .aspectRatio(3/4, contentMode: .fit)
                                                .overlay(ProgressView())
                                        }
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
    }
}
