import SwiftUI

struct ProfileSetupView: View {
    @EnvironmentObject var appState: AppFlowState
    @State private var showHardwareSelector = false
    @State private var showIdentityCapture = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 40) {
                VStack(spacing: 12) {
                    Text("WOVN Profile")
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(colors: [.white, .gray], startPoint: .top, endPoint: .bottom)
                        )
                    
                    Text("Capture your identity and spatial body metrics to generate hyper-realistic virtual try-ons.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                }
                .padding(.top, 40)
                
                VStack(spacing: 20) {
                    // Step 1: Identity Capture
                    Button(action: {
                        showIdentityCapture = true
                    }) {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.1))
                                    .frame(width: 50, height: 50)
                                Image(systemName: "face.dashed")
                                    .font(.title3)
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Step 1: Visual Identity")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text("Face, profile, & full body photo")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color.zinc800)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
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
                                    .foregroundColor(.white)
                                Text("Extract your millimeter measurements")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color.zinc800)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
            }
        }
        .confirmationDialog("Select Capture Hardware", isPresented: $showHardwareSelector, titleVisibility: .visible) {
            Button("iPhone Pro (LiDAR Scan)") {
                // Route to LiDAR Flow
                appState.currentRoute = .captureFlow
            }
            Button("Standard iPhone (2D Photo)") {
                // Route to 2D Vision Flow
                print("Routing to 2D Body Metrics Flow...")
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
