import SwiftUI

struct IdentityCaptureView: View {
    @EnvironmentObject var appState: AppFlowState
    
    @State private var isShowingCamera = false
    @State private var isShowingGuidedFaceCapture = false
    @State private var showHardwareSelector = false
    
    var body: some View {
        ZStack {
            // Sleek animated background to make the glass visible
            Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
            
            GeometryReader { proxy in
                Circle()
                    .fill(LinearGradient(colors: [.blue.opacity(0.2), .purple.opacity(0.3)], startPoint: .bottomTrailing, endPoint: .topLeading))
                    .frame(width: proxy.size.width * 1.5)
                    .blur(radius: 60)
                    .offset(x: -proxy.size.width * 0.2, y: -proxy.size.height * 0.2)
            }
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                HStack {
                    Button(action: {
                        withAnimation { appState.currentRoute = .onboardingBasic }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.5), lineWidth: 1))
                            .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                
                Text("Identity Capture")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("For Gemini to generate a hyper-realistic Virtual Try-On, we need high-resolution reference photos of your face and full body.")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                
                VStack(spacing: 16) {
                    
                    // Guided Face Scan Button
                    Button(action: {
                        isShowingGuidedFaceCapture = true
                    }) {
                        HStack(spacing: 16) {
                            if let face = appState.faceImage, let profile = appState.profileImage {
                                HStack(spacing: -10) {
                                    Image(uiImage: face).resizable().scaledToFill().frame(width: 50, height: 50).clipShape(Circle()).overlay(Circle().stroke(Color.green, lineWidth: 2))
                                    Image(uiImage: profile).resizable().scaledToFill().frame(width: 50, height: 50).clipShape(Circle()).overlay(Circle().stroke(Color.green, lineWidth: 2))
                                }
                            } else {
                                ZStack {
                                    Circle()
                                        .fill(Color.blue.opacity(0.1))
                                        .frame(width: 50, height: 50)
                                    Image(systemName: "faceid")
                                        .font(.title3)
                                        .foregroundColor(.blue)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Guided Face Scan")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text("Face ID style automated capture")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            
                            Image(systemName: (appState.faceImage != nil && appState.profileImage != nil) ? "checkmark.circle.fill" : "chevron.right")
                                .font(.title2)
                                .foregroundColor((appState.faceImage != nil && appState.profileImage != nil) ? .green : Color(uiColor: .tertiaryLabel))
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.5), lineWidth: 1))
                        .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
                    }
                    
                    // Full Body Photo Button
                    Button(action: {
                        isShowingCamera = true
                    }) {
                        HStack(spacing: 16) {
                            if let bodyImg = appState.bodyImage {
                                Image(uiImage: bodyImg).resizable().scaledToFill().frame(width: 50, height: 50).clipShape(Circle()).overlay(Circle().stroke(Color.green, lineWidth: 2))
                            } else {
                                ZStack {
                                    Circle()
                                        .fill(Color.purple.opacity(0.1))
                                        .frame(width: 50, height: 50)
                                    Image(systemName: "figure.stand")
                                        .font(.title3)
                                        .foregroundColor(.purple)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Full Body Photo")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text("Stand against a blank wall")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            
                            Image(systemName: appState.bodyImage != nil ? "checkmark.circle.fill" : "camera.circle")
                                .font(.title2)
                                .foregroundColor(appState.bodyImage != nil ? .green : Color(uiColor: .tertiaryLabel))
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.5), lineWidth: 1))
                        .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                Button(action: {
                    showHardwareSelector = true
                }) {
                    Text("Next: 3D Body Scan")
                        .font(.headline)
                        .foregroundColor(allPhotosCaptured ? .primary : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.8), lineWidth: 1))
                        .shadow(color: .black.opacity(0.05), radius: 15, y: 5)
                }
                .disabled(!allPhotosCaptured)
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.light)
        .fullScreenCover(isPresented: $isShowingGuidedFaceCapture) {
            GuidedFaceCaptureView(faceImage: $appState.faceImage, profileImage: $appState.profileImage)
        }
        .fullScreenCover(isPresented: $isShowingCamera) {
            ImagePicker(selectedImage: $appState.bodyImage, sourceType: .camera)
                .ignoresSafeArea()
        }
        .confirmationDialog("Select Capture Hardware", isPresented: $showHardwareSelector, titleVisibility: .visible) {
            Button("iPhone Pro (LiDAR Scan)") {
                appState.currentRoute = .lidarCaptureFlow
            }
            Button("Standard iPhone (2D Photo)") {
                appState.currentRoute = .standardCaptureFlow
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("LiDAR offers millimeter precision. If you don't have an iPhone Pro, our 2D AI can estimate your dimensions.")
        }
    }
    
    private var allPhotosCaptured: Bool {
        return appState.faceImage != nil && appState.profileImage != nil && appState.bodyImage != nil
    }
}
