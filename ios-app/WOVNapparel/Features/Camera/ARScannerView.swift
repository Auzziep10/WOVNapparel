import SwiftUI
import RealityKit

@available(iOS 17.0, *)
struct ARScannerView: View {
    @EnvironmentObject var appState: AppFlowState
    @State private var scanUrl: URL? = nil
    
    var body: some View {
        if let url = scanUrl {
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                
                Text("3D Human Scan Complete")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Model saved to: \(url.lastPathComponent)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Text("This 3D model will be uploaded to the server to extract exact body measurements.")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Button("Continue") {
                    appState.scannedModelURL = url
                    appState.currentRoute = .profileReview
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
                .padding(.horizontal, 40)
            }
            .preferredColorScheme(.light)
        } else {
            BodyScannerView { url in
                self.scanUrl = url
            }
            .preferredColorScheme(.dark) // ObjectCaptureView forces dark UI natively
        }
    }
}
