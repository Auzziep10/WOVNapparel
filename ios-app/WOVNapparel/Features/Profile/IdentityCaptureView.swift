import SwiftUI

struct IdentityCaptureView: View {
    @EnvironmentObject var appState: AppFlowState
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
            
            VStack(spacing: 30) {
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .padding()
                            .background(Color(uiColor: .secondarySystemGroupedBackground))
                            .clipShape(Circle())
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
                    CaptureStepRow(icon: "person.crop.square", title: "Face Close-up", description: "Straight-on face photo in good lighting")
                    CaptureStepRow(icon: "person.crop.square.filled.and.at.rectangle", title: "Profile View", description: "Side profile of your face and hair")
                    CaptureStepRow(icon: "figure.stand", title: "Full Body Photo", description: "Stand against a blank wall")
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                Button(action: {
                    // TODO: Open Camera to capture these 3 photos
                }) {
                    Text("Start Camera")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(16)
                        .shadow(color: .blue.opacity(0.3), radius: 10, y: 5)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 20)
            }
        }
        .preferredColorScheme(.light)
    }
}

struct CaptureStepRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 50, height: 50)
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "circle")
                .foregroundColor(Color(uiColor: .tertiaryLabel))
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
    }
}
