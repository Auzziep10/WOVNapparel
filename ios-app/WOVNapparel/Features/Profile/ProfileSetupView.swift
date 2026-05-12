import SwiftUI

struct ProfileSetupView: View {
    @EnvironmentObject var appState: AppFlowState
    @State private var showHardwareSelector = false
    @State private var showIdentityCapture = false
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
                .padding(.top, 20)
                
                // Basic Info Input
                VStack(spacing: 12) {
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
                
                VStack(spacing: 20) {
                    // Step 1: Identity Capture
                    Button(action: {
                        showIdentityCapture = true
                    }) {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.blue.opacity(0.1))
                                    .frame(width: 50, height: 50)
                                Image(systemName: "face.dashed")
                                    .font(.title3)
                                    .foregroundColor(.blue)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Step 1: Visual Identity")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text("Face, profile, & full body photo")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(Color(uiColor: .tertiaryLabel))
                        }
                        .padding()
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
                    }
                    
                    // Step 2: Spatial Body Capture
                    Button(action: {
                        showHardwareSelector = true
                    }) {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 50, height: 50)
                                Image(systemName: "viewfinder")
                                    .font(.title3)
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Step 2: 3D Body Metrics")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text("Extract your millimeter measurements")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(Color(uiColor: .tertiaryLabel))
                        }
                        .padding()
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
            }
        }
        .preferredColorScheme(.light)
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
        .fullScreenCover(isPresented: $showIdentityCapture) {
            IdentityCaptureView()
        }
    }
}

extension Color {
    static let zinc800 = Color(red: 39/255, green: 39/255, blue: 42/255)
}
