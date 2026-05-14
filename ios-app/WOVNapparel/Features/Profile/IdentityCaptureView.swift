import SwiftUI

struct IdentityCaptureView: View {
    @EnvironmentObject var appState: AppFlowState
    
    @State private var isShowingCamera = false
    @State private var isShowingGuidedFaceCapture = false
    @State private var showHardwareSelector = false
    @State private var showPhotoSourceSelector = false
    @State private var imageSourceType: UIImagePickerController.SourceType = .camera
    
    var body: some View {
        ZStack {
            // Minimalist Garment Catalog Background (#f4f4f5)
            Color(red: 244/255, green: 244/255, blue: 245/255).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Navigation
                HStack {
                    Button(action: {
                        withAnimation { appState.currentRoute = .onboardingBasic }
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 20, weight: .light))
                            .foregroundColor(Color.zinc900)
                            .padding()
                    }
                    Spacer()
                }
                .padding(.horizontal, 8)
                
                VStack(spacing: 16) {
                    Text("Identity Capture")
                        .font(.system(size: 44, weight: .regular, design: .serif))
                        .foregroundColor(Color.zinc900)
                        .multilineTextAlignment(.center)
                    
                    Text("For Gemini to generate a hyper-realistic Virtual Try-On, we need high-resolution reference photos of your face and full body.")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Color.zinc500)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .lineSpacing(4)
                }
                .padding(.top, 10)
                .padding(.bottom, 40)
                
                VStack(spacing: 16) {
                    
                    // Guided Face Scan Button
                    Button(action: {
                        isShowingGuidedFaceCapture = true
                    }) {
                        HStack(spacing: 16) {
                            if let face = appState.faceImage, let profile = appState.profileImage {
                                HStack(spacing: -10) {
                                    Image(uiImage: face).resizable().scaledToFill().frame(width: 40, height: 40).clipShape(Circle()).overlay(Circle().stroke(Color.zinc200, lineWidth: 1))
                                    Image(uiImage: profile).resizable().scaledToFill().frame(width: 40, height: 40).clipShape(Circle()).overlay(Circle().stroke(Color.zinc200, lineWidth: 1))
                                }
                            } else {
                                ZStack {
                                    Circle()
                                        .fill(Color(white: 0.96))
                                        .frame(width: 40, height: 40)
                                    Image(systemName: "faceid")
                                        .font(.system(size: 16))
                                        .foregroundColor(Color.zinc900)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("GUIDED FACE SCAN")
                                    .font(.system(size: 10, weight: .semibold))
                                    .tracking(1.5)
                                    .foregroundColor(Color.zinc900)
                                Text("Face ID style automated capture")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color.zinc500)
                            }
                            Spacer()
                            
                            Image(systemName: (appState.faceImage != nil && appState.profileImage != nil) ? "checkmark" : "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor((appState.faceImage != nil && appState.profileImage != nil) ? Color.zinc900 : Color.zinc400)
                        }
                        .padding()
                        .background(Color.white)
                        .border(Color.zinc200, width: 1)
                    }
                    
                    // Full Body Photo Button
                    Button(action: {
                        showPhotoSourceSelector = true
                    }) {
                        HStack(spacing: 16) {
                            if let bodyImg = appState.bodyImage {
                                Image(uiImage: bodyImg).resizable().scaledToFill().frame(width: 40, height: 40).clipShape(Circle()).overlay(Circle().stroke(Color.zinc200, lineWidth: 1))
                            } else {
                                ZStack {
                                    Circle()
                                        .fill(Color(white: 0.96))
                                        .frame(width: 40, height: 40)
                                    Image(systemName: "figure.stand")
                                        .font(.system(size: 16))
                                        .foregroundColor(Color.zinc900)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("FULL BODY PHOTO")
                                    .font(.system(size: 10, weight: .semibold))
                                    .tracking(1.5)
                                    .foregroundColor(Color.zinc900)
                                Text("Aesthetic reference photo for AI")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color.zinc500)
                            }
                            Spacer()
                            
                            Image(systemName: appState.bodyImage != nil ? "checkmark" : "camera")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(appState.bodyImage != nil ? Color.zinc900 : Color.zinc400)
                        }
                        .padding()
                        .background(Color.white)
                        .border(Color.zinc200, width: 1)
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                Button(action: {
                    showHardwareSelector = true
                }) {
                    Text("NEXT: 3D BODY SCAN")
                        .font(.system(size: 12, weight: .semibold))
                        .tracking(2)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(allPhotosCaptured ? Color.zinc900 : Color.zinc300)
                }
                .disabled(!allPhotosCaptured)
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.light)
        .fullScreenCover(isPresented: $isShowingGuidedFaceCapture) {
            GuidedFaceCaptureView(faceImage: $appState.faceImage, profileImage: $appState.profileImage)
        }
        .fullScreenCover(isPresented: $isShowingCamera) {
            ImagePicker(selectedImage: $appState.bodyImage, sourceType: imageSourceType)
                .ignoresSafeArea()
        }
        .confirmationDialog("Select Photo Source", isPresented: $showPhotoSourceSelector, titleVisibility: .visible) {
            Button("Photo Library") {
                imageSourceType = .photoLibrary
                isShowingCamera = true
            }
            Button("Take Photo") {
                imageSourceType = .camera
                isShowingCamera = true
            }
            Button("Cancel", role: .cancel) {}
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
