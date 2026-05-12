import SwiftUI
import RealityKit
import Combine

@available(iOS 17.0, *)
public struct BodyScannerView: View {
    @State private var session = ObjectCaptureSession()
    var onComplete: (URL?) -> Void
    
    @State private var isProcessing = false
    @State private var progress: Double = 0.0
    @State private var captureDirectory: URL? = nil
    @State private var errorMessage: String? = nil

    public var body: some View {
        ZStack {
            if let error = errorMessage {
                VStack {
                    Text("Scanner Error")
                        .font(.headline)
                        .foregroundColor(.red)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                    Button("Retry") {
                        errorMessage = nil
                        startNewSession()
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            } else if !isProcessing {
                // The actual camera feed
                if #available(iOS 18.0, *) {
                    iOS18ObjectCaptureWrapper(session: session)
                        .edgesIgnoringSafeArea(.all)
                } else {
                    ObjectCaptureView(session: session)
                        .edgesIgnoringSafeArea(.all)
                }
                
                // Top Bar (Logo)
                VStack {
                    HStack {
                        Spacer()
                        Text("WOVN")
                            .font(.system(size: 28, weight: .light, design: .default))
                            .tracking(3)
                            .foregroundColor(.white)
                            .padding(.top, 20)
                        Spacer()
                    }
                    Spacer()
                }
                
                // Bottom Controls
                VStack {
                    Spacer()
                    
                    if case .initializing = session.state {
                        ProgressView()
                            .colorInvert()
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    } else if case .ready = session.state {
                        Button(action: { session.startDetecting() }) {
                            Text("SETUP BOX")
                                .font(.system(size: 14, weight: .bold))
                                .tracking(2)
                                .foregroundColor(.white)
                                .padding(.horizontal, 40)
                                .frame(height: 56)
                                .background(.ultraThinMaterial)
                                .environment(\.colorScheme, .dark)
                                .overlay(
                                    Capsule().stroke(Color.white.opacity(0.4), lineWidth: 1)
                                )
                                .clipShape(Capsule())
                        }
                    } else if case .detecting = session.state {
                        Button(action: { session.startCapturing() }) {
                            Text("START SCAN")
                                .font(.system(size: 14, weight: .bold))
                                .tracking(2)
                                .foregroundColor(.white)
                                .padding(.horizontal, 40)
                                .frame(height: 56)
                                .background(.ultraThinMaterial)
                                .environment(\.colorScheme, .dark)
                                .overlay(
                                    Capsule().stroke(Color.white.opacity(0.4), lineWidth: 1)
                                )
                                .clipShape(Capsule())
                        }
                    } else if case .capturing = session.state {
                        Button(action: { session.finish() }) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 72, height: 72)
                                .background(Color(red: 1.0, green: 0.23, blue: 0.19)) // #ff3b30
                                .clipShape(Circle())
                        }
                    }
                }.padding(.bottom, 50)
                
            } else {
                // Processing View
                ZStack {
                    Color.black.opacity(0.85).ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        if progress > 0 {
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.white.opacity(0.2))
                                        .frame(height: 8)
                                    
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.white)
                                        .frame(width: max(geometry.size.width * 0.05, geometry.size.width * progress), height: 8)
                                }
                            }
                            .frame(width: UIScreen.main.bounds.width * 0.7, height: 8)
                        } else {
                            ProgressView()
                                .scaleEffect(1.5)
                                .colorInvert()
                        }
                        
                        Text(progress > 0 ? "Processing 3D Model... \(Int(progress * 100))%" : "Preparing Photogrammetry...")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.top, 10)
                        
                        Text("This may take a few minutes depending on the device.")
                            .font(.system(size: 14))
                            .foregroundColor(Color(white: 0.66)) // #aaa
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                }
            }
        }
        .onAppear {
            startNewSession()
        }
    }
    
    private func startNewSession() {
        guard ObjectCaptureSession.isSupported else {
            errorMessage = "Object Capture is not supported on this device. Requires LiDAR."
            return
        }
        
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("BodyScan-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.captureDirectory = dir
        
        var config = ObjectCaptureSession.Configuration()
        
        // Listen to state updates to trigger processing safely (prevents GPU background crash)
        Task {
            for await state in session.stateUpdates {
                if case .completed = state {
                    DispatchQueue.main.async {
                        self.isProcessing = true
                        if let imagesDir = self.captureDirectory {
                            self.processPhotogrammetry(imagesDir: imagesDir)
                        } else {
                            self.onComplete(nil)
                        }
                    }
                } else if case .failed(let error) = state {
                    DispatchQueue.main.async {
                        self.errorMessage = "Capture failed: \(error.localizedDescription)"
                    }
                }
            }
        }
        
        session.start(imagesDirectory: dir, configuration: config)
    }
    
    private func processPhotogrammetry(imagesDir: URL) {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let usdzFileURL = paths[0].appendingPathComponent("BodyScan-\(UUID().uuidString).usdz")
        
        Task {
            do {
                // Use the select_fit optimized framework config
                let request = PhotogrammetrySession.Request.modelFile(url: usdzFileURL, detail: .reduced)
                var config = PhotogrammetrySession.Configuration()
                config.isObjectMaskingEnabled = true
                config.sampleOrdering = .sequential
                config.featureSensitivity = .high
                
                let pSession = try PhotogrammetrySession(input: imagesDir, configuration: config)
                try pSession.process(requests: [request])
                
                for try await output in pSession.outputs {
                    switch output {
                    case .processingComplete:
                        DispatchQueue.main.async {
                            onComplete(usdzFileURL)
                        }
                    case .requestProgress(_, let fractionComplete):
                        DispatchQueue.main.async {
                            self.progress = fractionComplete
                        }
                    case .requestError(_, let error):
                        DispatchQueue.main.async {
                            self.errorMessage = "Photogrammetry failed: \(error.localizedDescription)"
                            self.isProcessing = false
                        }
                    default:
                        break
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Processing Error: \(error.localizedDescription)"
                    self.isProcessing = false
                }
            }
        }
    }
}

@available(iOS 18.0, *)
struct iOS18ObjectCaptureWrapper: View {
    var session: ObjectCaptureSession
    var body: some View {
        ObjectCaptureView(session: session)
    }
}
