import SwiftUI

struct IdentityCaptureView: View {
    @EnvironmentObject var appState: AppFlowState
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 30) {
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                .padding(.horizontal)
                
                Text("Identity Capture")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("For Gemini to generate a hyper-realistic Virtual Try-On, we need high-resolution reference photos of your face and full body.")
                    .foregroundColor(.gray)
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
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 20)
            }
        }
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
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 50, height: 50)
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
            Image(systemName: "circle")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.zinc800)
        .cornerRadius(16)
    }
}
