import SwiftUI

struct IdentityCaptureView: View {
    @EnvironmentObject var appState: AppFlowState
    
    @State private var currentStep = 0 // 0: Try-On Photo, 1: Face Scan, 2: Scan Method Selection
    @State private var isShowingCamera = false
    @State private var isShowingGuidedFaceCapture = false
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
                        withAnimation {
                            if currentStep > 0 {
                                currentStep -= 1
                            } else {
                                appState.currentRoute = .onboardingBasic
                            }
                        }
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 20, weight: .light))
                            .foregroundColor(Color.zinc900)
                            .padding()
                    }
                    Spacer()
                }
                .padding(.horizontal, 8)
                
                if currentStep == 0 {
                    // STEP 0: TRY-ON REFERENCE PHOTO
                    tryOnPhotoStepView
                } else if currentStep == 1 {
                    // STEP 1: GUIDED FACE SCAN
                    faceScanStepView
                } else {
                    // STEP 2: SIZING METHOD SELECTION
                    sizingSelectionStepView
                }
            }
        }
        .preferredColorScheme(.light)
        .fullScreenCover(isPresented: $isShowingGuidedFaceCapture) {
            GuidedFaceCaptureView(faceImage: $appState.faceImage, profileImage: $appState.profileImage)
        }
        .onChange(of: appState.faceImage) { newFaceImage in
            if let image = newFaceImage {
                Task { @MainActor in
                    let index = await ChromaticAnalyzer.analyzeContrast(image: image)
                    appState.userMetrics["chromaticContrastIndex"] = index
                }
            }
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
    }
    
    // MARK: - Step 0: Try-On Photo View
    private var tryOnPhotoStepView: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 40) {
                    VStack(spacing: 16) {
                        Text("Try-On Canvas")
                            .font(.system(size: 44, weight: .regular, design: .serif))
                            .foregroundColor(Color.zinc900)
                            .multilineTextAlignment(.center)
                        
                        Text("Take or upload the main photo of yourself that you want to try clothes on. For best results, stand straight in form-fitting clothes with good lighting.")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Color.zinc500)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .lineSpacing(4)
                    }
                    .padding(.top, 10)
                    
                    // Photo Area
                    ZStack {
                        if let bodyImg = appState.bodyImage {
                            Image(uiImage: bodyImg)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 240, height: 320)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.zinc200, lineWidth: 1))
                                .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
                        } else {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white)
                                .frame(width: 240, height: 320)
                                .overlay(
                                    VStack(spacing: 16) {
                                        Image(systemName: "figure.stand")
                                            .font(.system(size: 48, weight: .thin))
                                            .foregroundColor(Color.zinc400)
                                        Text("No Photo Uploaded")
                                            .font(.system(size: 12, weight: .bold))
                                            .tracking(1.0)
                                            .foregroundColor(Color.zinc400)
                                    }
                                )
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.zinc200, lineWidth: 1))
                        }
                    }
                    
                    // Actions
                    Button(action: {
                        showPhotoSourceSelector = true
                    }) {
                        Text(appState.bodyImage == nil ? "SELECT OR TAKE PHOTO" : "CHANGE PHOTO")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(1.5)
                            .foregroundColor(.white)
                            .padding(.vertical, 16)
                            .frame(width: 240)
                            .background(Color.zinc900)
                            .clipShape(Capsule())
                            .shadow(color: Color.black.opacity(0.12), radius: 8, y: 4)
                    }
                }
                .padding(.bottom, 40)
            }
            
            Spacer()
            
            // Bottom Button
            Button(action: {
                withAnimation {
                    currentStep = 1
                }
            }) {
                Text("NEXT: CAPTURE METRICS")
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(2.5)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(appState.bodyImage == nil ? Color.zinc300 : Color.zinc900)
                    .clipShape(Capsule())
                    .shadow(color: appState.bodyImage == nil ? .clear : Color.black.opacity(0.12), radius: 10, y: 5)
            }
            .disabled(appState.bodyImage == nil)
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Step 1: Face Scan View
    private var faceScanStepView: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 40) {
                    VStack(spacing: 16) {
                        Text("Face Scan")
                            .font(.system(size: 44, weight: .regular, design: .serif))
                            .foregroundColor(Color.zinc900)
                            .multilineTextAlignment(.center)
                        
                        Text("Next, we'll scan your face to analyze skin tone and contrast. This ensures color recommendations complement your complexion.")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Color.zinc500)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .lineSpacing(4)
                    }
                    .padding(.top, 10)
                    
                    // Face Scan Status Card
                    ZStack {
                        if let face = appState.faceImage, let profile = appState.profileImage {
                            HStack(spacing: 20) {
                                Image(uiImage: face)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 110, height: 140)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.zinc200, lineWidth: 1))
                                
                                Image(uiImage: profile)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 110, height: 140)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.zinc200, lineWidth: 1))
                            }
                        } else {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white)
                                .frame(width: 240, height: 160)
                                .overlay(
                                    VStack(spacing: 16) {
                                        Image(systemName: "faceid")
                                            .font(.system(size: 40, weight: .thin))
                                            .foregroundColor(Color.zinc400)
                                        Text("Scan Face to Calibrate Colors")
                                            .font(.system(size: 11, weight: .bold))
                                            .tracking(1.0)
                                            .foregroundColor(Color.zinc400)
                                    }
                                )
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.zinc200, lineWidth: 1))
                        }
                    }
                    
                    // Action
                    Button(action: {
                        isShowingGuidedFaceCapture = true
                    }) {
                        Text(isFaceScanComplete ? "RETAKE FACE SCAN" : "START GUIDED FACE SCAN")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(1.5)
                            .foregroundColor(.white)
                            .padding(.vertical, 16)
                            .frame(width: 240)
                            .background(Color.zinc900)
                            .clipShape(Capsule())
                            .shadow(color: Color.black.opacity(0.12), radius: 8, y: 4)
                    }
                    
                    if let contrast = appState.userMetrics["chromaticContrastIndex"] {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .foregroundColor(.blue)
                            Text("Contrast Index: \(Int(contrast)) (\(contrast > 60 ? "High" : "Low"))")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.blue)
                        }
                    }
                }
                .padding(.bottom, 40)
            }
            
            Spacer()
            
            // Bottom Button
            Button(action: {
                withAnimation {
                    currentStep = 2
                }
            }) {
                Text("NEXT: SELECT SIZING METHOD")
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(2.5)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(!isFaceScanComplete ? Color.zinc300 : Color.zinc900)
                    .clipShape(Capsule())
                    .shadow(color: !isFaceScanComplete ? .clear : Color.black.opacity(0.12), radius: 10, y: 5)
            }
            .disabled(!isFaceScanComplete)
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Step 2: Sizing Method Selection View
    private var sizingSelectionStepView: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    VStack(spacing: 16) {
                        Text("Sizing Scan")
                            .font(.system(size: 44, weight: .regular, design: .serif))
                            .foregroundColor(Color.zinc900)
                            .multilineTextAlignment(.center)
                        
                        Text("Choose a method to scan your body measurements. LiDAR offers millimeter precision, while our refined 2D engine estimates size using your phone's camera.")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Color.zinc500)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .lineSpacing(4)
                    }
                    .padding(.top, 10)
                    
                    VStack(spacing: 20) {
                        // Method 1: 2D Selfie Scan
                        Button(action: {
                            withAnimation {
                                appState.currentRoute = .standardCaptureFlow
                            }
                        }) {
                            VStack(alignment: .leading, spacing: 14) {
                                HStack {
                                    Text("2D BODY SELFIE SCAN")
                                        .font(.system(size: 11, weight: .bold))
                                        .tracking(1.5)
                                        .foregroundColor(Color.zinc900)
                                    Spacer()
                                    Text("RECOMMENDED")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(.blue)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(4)
                                }
                                
                                Text("Stand in front of your camera. Uses your front-facing selfie camera with real-time AR skeletal tracking. Self-guided, takes 2 seconds.")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color.zinc500)
                                    .multilineTextAlignment(.leading)
                                    .lineSpacing(2)
                                
                                HStack {
                                    Text("Start 2D Scan")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 10)
                                        .background(Color.zinc900)
                                        .clipShape(Capsule())
                                        .shadow(color: Color.black.opacity(0.1), radius: 5, y: 2)
                                    Spacer()
                                    Image(systemName: "camera.fill")
                                        .foregroundColor(Color.zinc900)
                                }
                                .padding(.top, 8)
                            }
                            .padding(20)
                            .background(Color.white)
                            .cornerRadius(20)
                            .shadow(color: .black.opacity(0.02), radius: 10, y: 5)
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.zinc200, lineWidth: 1))
                        }
                        
                        // Method 2: 3D LiDAR Scan
                        Button(action: {
                            withAnimation {
                                appState.currentRoute = .lidarCaptureFlow
                            }
                        }) {
                            VStack(alignment: .leading, spacing: 14) {
                                HStack {
                                    Text("3D LIDAR BODY SCAN")
                                        .font(.system(size: 11, weight: .bold))
                                        .tracking(1.5)
                                        .foregroundColor(Color.zinc900)
                                    Spacer()
                                    Text("IPHONE PRO ONLY")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(.gray)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(4)
                                }
                                
                                Text("⚠️ TWO-PERSON JOB: You will need a friend to hold the phone and scan your body in 3D while you stand still.")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.leading)
                                    .lineSpacing(2)
                                
                                Text("Generates a millimeter-precision 3D mesh utilizing the LiDAR scanner. Friend-guided capture.")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color.zinc500)
                                    .multilineTextAlignment(.leading)
                                    .lineSpacing(2)
                                
                                HStack {
                                    Text("Start 3D Scan")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 10)
                                        .background(Color.zinc900)
                                        .clipShape(Capsule())
                                        .shadow(color: Color.black.opacity(0.1), radius: 5, y: 2)
                                    Spacer()
                                    Image(systemName: "arkit")
                                        .foregroundColor(Color.zinc900)
                                }
                                .padding(.top, 8)
                            }
                            .padding(20)
                            .background(Color.white)
                            .cornerRadius(20)
                            .shadow(color: .black.opacity(0.02), radius: 10, y: 5)
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.zinc200, lineWidth: 1))
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 40)
            }
        }
    }
    
    private var isFaceScanComplete: Bool {
        return appState.faceImage != nil && appState.profileImage != nil
    }
}
