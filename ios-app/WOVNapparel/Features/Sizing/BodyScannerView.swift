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
                
                // UI Overlay
                VStack {
                    if case .capturing = session.state {
                        HStack(spacing: 20) {
                            Spacer()
                            
                            if session.userCompletedScanPass {
                                Button(action: {
                                    if !session.isPaused { session.pause() }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                        session.beginNewScanPassAfterFlip()
                                    }
                                }) {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                        .font(.title2).foregroundColor(.orange)
                                        .frame(width: 50, height: 50)
                                        .background(.ultraThinMaterial).clipShape(Circle())
                                }
                            } else {
                                Button(action: { session.pause() }) {
                                    Image(systemName: "pause.fill")
                                        .font(.title2).foregroundColor(session.isPaused ? .gray : .yellow)
                                        .frame(width: 50, height: 50)
                                        .background(.ultraThinMaterial).clipShape(Circle())
                                }
                                .disabled(session.isPaused)
                            }
                            
                            Button(action: { session.finish() }) {
                                Image(systemName: "checkmark")
                                    .font(.title2).foregroundColor(.green)
                                    .frame(width: 50, height: 50)
                                    .background(.ultraThinMaterial).clipShape(Circle())
                            }
                        }
                        .padding(.top, 60)
                        .padding(.trailing, 20)
                    }
                    Spacer()
                    
                    // Bottom Controls
                    if case .initializing = session.state {
                        VStack {
                            ProgressView().scaleEffect(1.5).padding()
                            Text("Warming up LiDAR...").foregroundColor(.white)
                        }.padding().background(Color.black.opacity(0.7)).cornerRadius(20)
                        
                    } else if case .ready = session.state {
                        Button(action: { session.startCapturing() }) {
                            Text("Start Scanning")
                                .font(.headline).foregroundColor(.white)
                                .padding(.horizontal, 40).padding(.vertical, 16)
                                .background(Color.blue).clipShape(Capsule())
                        }
                    } else if case .completed = session.state {
                        Color.clear.task {
                            isProcessing = true
                            guard let imagesDir = captureDirectory else {
                                onComplete(nil)
                                return
                            }
                            processPhotogrammetry(imagesDir: imagesDir)
                        }
                    }
                }.padding(.bottom, 50)
                
            } else {
                // Processing View
                VStack(spacing: 20) {
                    ProgressView().scaleEffect(2.0)
                    Text("Building Photorealistic 3D Model...")
                        .font(.headline)
                    Text("This uses the select_fit memory-optimized engine.")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("\(Int(progress * 100))%")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.ignoresSafeArea())
                .foregroundColor(.white)
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
