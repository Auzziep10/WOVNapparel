import SwiftUI

struct IdentityCaptureView: View {
    @EnvironmentObject var appState: AppFlowState
    
    @State private var faceImage: UIImage?
    @State private var profileImage: UIImage?
    @State private var bodyImage: UIImage?
    
    @State private var isShowingCamera = false
    @State private var activeCaptureStep: CaptureStep? = nil
    @State private var showHardwareSelector = false
    
    enum CaptureStep {
        case face, profile, body
    }
    
    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
            
            VStack(spacing: 20) {
                HStack {
                    Button(action: {
                        withAnimation { appState.currentRoute = .onboarding }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .padding()
                            .background(Color(uiColor: .secondarySystemGroupedBackground))
                            .clipShape(Circle())
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
                    CaptureStepRow(icon: "person.crop.square", title: "Face Close-up", description: "Straight-on face photo in good lighting", image: faceImage) {
                        activeCaptureStep = .face
                        isShowingCamera = true
                    }
                    CaptureStepRow(icon: "person.crop.square.filled.and.at.rectangle", title: "Profile View", description: "Side profile of your face and hair", image: profileImage) {
                        activeCaptureStep = .profile
                        isShowingCamera = true
                    }
                    CaptureStepRow(icon: "figure.stand", title: "Full Body Photo", description: "Stand against a blank wall", image: bodyImage) {
                        activeCaptureStep = .body
                        isShowingCamera = true
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                Button(action: {
                    showHardwareSelector = true
                }) {
                    Text("Next: 3D Body Scan")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(allPhotosCaptured ? Color.blue : Color.blue.opacity(0.5))
                        .cornerRadius(16)
                        .shadow(color: .blue.opacity(0.3), radius: 10, y: 5)
                }
                .disabled(!allPhotosCaptured)
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.light)
        .fullScreenCover(isPresented: $isShowingCamera) {
            ImagePicker(selectedImage: bindingForActiveStep(), sourceType: .camera)
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
        return faceImage != nil && profileImage != nil && bodyImage != nil
    }
    
    private func bindingForActiveStep() -> Binding<UIImage?> {
        switch activeCaptureStep {
        case .face: return $faceImage
        case .profile: return $profileImage
        case .body: return $bodyImage
        case .none: return .constant(nil)
        }
    }
}

struct CaptureStepRow: View {
    let icon: String
    let title: String
    let description: String
    let image: UIImage?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                if let img = image {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.green, lineWidth: 2))
                } else {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 50, height: 50)
                        Image(systemName: icon)
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                
                Image(systemName: image != nil ? "checkmark.circle.fill" : "camera.circle")
                    .font(.title2)
                    .foregroundColor(image != nil ? .green : Color(uiColor: .tertiaryLabel))
            }
            .padding()
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
        }
    }
}
