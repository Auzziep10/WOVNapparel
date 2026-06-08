import SwiftUI
import SceneKit

struct ProfileDashboardView: View {
    @EnvironmentObject var appState: AppFlowState
    @State private var showARQuickLook = false
    @State private var showEditMenu = false
    @State private var showAdjustSheet = false
    
    var body: some View {
        ZStack {
            Color(red: 244/255, green: 244/255, blue: 245/255).ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 40) {
                        
                        // TOP NAV & HEADER
                        VStack(spacing: 12) {
                            HStack {
                                Spacer()
                                Button(action: {
                                    showEditMenu = true
                                }) {
                                    Image(systemName: "gearshape.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(Color(red: 161/255, green: 161/255, blue: 170/255))
                                        .padding(12)
                                        .background(Color.white)
                                        .clipShape(Circle())
                                        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
                                }
                                .padding(.trailing, 24)
                            }
                            
                            Text("Identity Captured")
                                .font(.system(size: 36, weight: .regular, design: .serif))
                                .foregroundColor(Color(red: 24/255, green: 24/255, blue: 27/255))
                            
                            Text("Your spatial profile and reference photos are securely locked in and ready for Virtual Try-On.")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(Color(red: 113/255, green: 113/255, blue: 122/255))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                                .lineSpacing(4)
                        }
                        .padding(.top, 20)
                        
                        // MEASUREMENTS SECTION
                        if !appState.userMetrics.isEmpty {
                            VStack(spacing: 16) {
                                HStack {
                                    Text("MEASUREMENTS")
                                        .font(.system(size: 10, weight: .bold))
                                        .tracking(1.5)
                                        .foregroundColor(Color(red: 161/255, green: 161/255, blue: 170/255))
                                    Spacer()
                                    Button(action: {
                                        showAdjustSheet = true
                                    }) {
                                        Text("ADJUST")
                                            .font(.system(size: 9, weight: .bold))
                                            .tracking(1.0)
                                            .foregroundColor(.black)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color(red: 228/255, green: 228/255, blue: 231/255))
                                            .clipShape(Capsule())
                                    }
                                }
                                .padding(.horizontal, 24)
                                
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                    let displayMetrics = appState.userMetrics.filter { 
                                        !$0.key.lowercased().starts(with: "skin") && 
                                        !$0.key.lowercased().starts(with: "chromatic") 
                                    }.sorted(by: <)
                                    
                                    ForEach(displayMetrics, id: \.key) { key, value in
                                        let displayValue = key.lowercased().contains("cm") ? value / 2.54 : value
                                        VStack(spacing: 4) {
                                            Text(String(format: "%.1f\"", displayValue))
                                                .font(.system(size: 18, weight: .medium, design: .serif))
                                                .foregroundColor(.black)
                                            Text(key.uppercased().replacingOccurrences(of: "CM", with: ""))
                                                .font(.system(size: 10, weight: .bold))
                                                .tracking(1.0)
                                                .foregroundColor(.gray)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(Color.white)
                                        .cornerRadius(12)
                                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(red: 228/255, green: 228/255, blue: 231/255), lineWidth: 1))
                                    }
                                }
                                .padding(.horizontal, 24)
                            }
                        }
                        
                        // SAVED TRY-ONS
                        if !appState.savedTryOns.isEmpty {
                            VStack(spacing: 16) {
                                HStack {
                                    Text("SAVED TRY-ONS")
                                        .font(.system(size: 10, weight: .bold))
                                        .tracking(1.5)
                                        .foregroundColor(Color(red: 161/255, green: 161/255, blue: 170/255))
                                    Spacer()
                                }
                                .padding(.horizontal, 24)
                                Button(action: {
                                    appState.currentRoute = .gallery
                                }) {
                                    HStack {
                                        Image(systemName: "photo.stack")
                                            .font(.system(size: 20))
                                            .foregroundColor(.black)
                                        
                                        Text("View Past Try-Ons Gallery")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.black)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.vertical, 16)
                                    .padding(.horizontal, 20)
                                    .background(Color.white)
                                    .cornerRadius(12)
                                    .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
                                }
                                .padding(.horizontal, 24)
                            }
                        }
                        
                        // AVATAR ROW (Face & Profile)
                        HStack(spacing: 40) {
                            if let face = appState.faceImage {
                                AvatarThumbnail(image: face, label: "FACE")
                            } else if let remoteFace = appState.remoteFaceURL {
                                RemoteAvatarThumbnail(urlString: remoteFace, label: "FACE")
                            }
                            
                            if let profile = appState.profileImage {
                                AvatarThumbnail(image: profile, label: "PROFILE")
                            } else if let remoteProfile = appState.remoteProfileURL {
                                RemoteAvatarThumbnail(urlString: remoteProfile, label: "PROFILE")
                            }
                        }
                        
                        // HERO IMAGE (Full Body)
                        if let bodyImage = appState.bodyImage {
                            HeroPhotoThumbnail(image: bodyImage, label: "FULL BODY")
                        } else if let remoteBody = appState.remoteBodyURL {
                            RemoteHeroPhotoThumbnail(urlString: remoteBody, label: "FULL BODY")
                        }
                        
                        // 3D SPATIAL SCAN (RealityKit + QuickLook)
                        if let modelURL = appState.scannedModelURL {
                            VStack(spacing: 16) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white)
                                        .frame(maxWidth: UIScreen.main.bounds.width - 48, minHeight: 300)
                                        .shadow(color: .black.opacity(0.08), radius: 20, y: 10)
                                    
                                    if let scene = try? SCNScene(url: modelURL) {
                                        SceneView(
                                            scene: scene,
                                            options: [.autoenablesDefaultLighting, .allowsCameraControl]
                                        )
                                        .frame(height: 300)
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                    } else {
                                        Text("Failed to load 3D Scan")
                                            .foregroundColor(.gray)
                                    }
                                }
                                
                                HStack(spacing: 16) {
                                    Text("SPATIAL 3D SCAN")
                                        .font(.system(size: 10, weight: .bold))
                                        .tracking(1.5)
                                        .foregroundColor(Color(red: 161/255, green: 161/255, blue: 170/255))
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        showARQuickLook = true
                                    }) {
                                        HStack {
                                            Image(systemName: "arkit")
                                            Text("VIEW IN AR")
                                        }
                                        .font(.system(size: 10, weight: .bold))
                                        .tracking(1.5)
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Color(red: 228/255, green: 228/255, blue: 231/255))
                                        .cornerRadius(20)
                                    }
                                }
                                .padding(.horizontal, 24)
                            }
                            .padding(.top, 20)
                        }
                        
                        Spacer(minLength: 40)
                    }
                }
                .sheet(isPresented: $showARQuickLook) {
                    if let modelURL = appState.scannedModelURL {
                        ARQuickLookView(url: modelURL)
                    }
                }
                .sheet(isPresented: $showAdjustSheet) {
                    AdjustmentSheet()
                }
                .confirmationDialog("Edit Profile", isPresented: $showEditMenu, titleVisibility: .visible) {
                    Button("Edit Personal Info") {
                        appState.currentRoute = .onboardingBasic
                    }
                    Button("Retake Reference Photos") {
                        appState.currentRoute = .onboardingPhotos
                    }
                    Button("Retake 3D Spatial Scan") {
                        appState.currentRoute = .lidarCaptureFlow
                    }
                    Button("Sign Out", role: .destructive) {
                        appState.signOut()
                    }
                    Button("Cancel", role: .cancel) { }
                }
                
                // BOTTOM ACTION BAR
                VStack {
                    Divider()
                    Button(action: {
                        withAnimation {
                            appState.currentRoute = .occasionSelection
                        }
                    }) {
                        Text("START TRY-ON")
                            .font(.system(size: 12, weight: .bold))
                            .tracking(2.5)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color(red: 24/255, green: 24/255, blue: 27/255))
                            .clipShape(Capsule())
                            .shadow(color: Color.black.opacity(0.12), radius: 10, y: 5)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                }
                .background(Color(red: 250/255, green: 250/255, blue: 250/255).ignoresSafeArea(edges: .bottom))
            }
        }
        .preferredColorScheme(.light)
    }
}

struct AvatarThumbnail: View {
    let image: UIImage
    let label: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 120, height: 160)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(red: 228/255, green: 228/255, blue: 231/255), lineWidth: 1))
                .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
            
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .tracking(1.5)
                .foregroundColor(Color(red: 161/255, green: 161/255, blue: 170/255))
        }
    }
}

struct HeroPhotoThumbnail: View {
    let image: UIImage
    let label: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: UIScreen.main.bounds.width - 48, maxHeight: 450)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(red: 228/255, green: 228/255, blue: 231/255), lineWidth: 1))
                .shadow(color: .black.opacity(0.08), radius: 20, y: 10)
            
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .tracking(1.5)
                .foregroundColor(Color(red: 161/255, green: 161/255, blue: 170/255))
        }
    }
}

struct RemoteAvatarThumbnail: View {
    let urlString: String
    let label: String
    
    var body: some View {
        VStack(spacing: 12) {
            AsyncImage(url: URL(string: urlString)) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 160)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(red: 228/255, green: 228/255, blue: 231/255), lineWidth: 1))
                        .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(red: 228/255, green: 228/255, blue: 231/255))
                        .frame(width: 120, height: 160)
                }
            }
            
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .tracking(1.5)
                .foregroundColor(Color(red: 161/255, green: 161/255, blue: 170/255))
        }
    }
}

struct RemoteHeroPhotoThumbnail: View {
    let urlString: String
    let label: String
    
    var body: some View {
        VStack(spacing: 16) {
            AsyncImage(url: URL(string: urlString)) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: UIScreen.main.bounds.width - 48, maxHeight: 450)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(red: 228/255, green: 228/255, blue: 231/255), lineWidth: 1))
                        .shadow(color: .black.opacity(0.08), radius: 20, y: 10)
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(red: 228/255, green: 228/255, blue: 231/255))
                        .frame(maxWidth: UIScreen.main.bounds.width - 48, maxHeight: 450)
                }
            }
            
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .tracking(1.5)
                .foregroundColor(Color(red: 161/255, green: 161/255, blue: 170/255))
        }
    }
}

struct AdjustmentSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppFlowState
    
    @State private var chestInches: String = ""
    @State private var waistInches: String = ""
    @State private var hipsInches: String = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 244/255, green: 244/255, blue: 245/255).ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Text("Fine-Tune Measurements")
                        .font(.system(size: 28, weight: .regular, design: .serif))
                        .foregroundColor(Color(red: 24/255, green: 24/255, blue: 27/255))
                        .padding(.top, 20)
                    
                    Text("If the 2D spatial scan estimated your proportions slightly off, adjust them here in inches.")
                        .font(.system(size: 14))
                        .foregroundColor(Color(red: 113/255, green: 113/255, blue: 122/255))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .lineSpacing(4)
                    
                    VStack(spacing: 20) {
                        MetricInputRow(label: "CHEST (IN)", value: $chestInches)
                        MetricInputRow(label: "WAIST (IN)", value: $waistInches)
                        MetricInputRow(label: "HIPS (IN)", value: $hipsInches)
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                    
                    Button(action: {
                        saveChanges()
                    }) {
                        Text("SAVE & UPDATE PROFILE")
                            .font(.system(size: 12, weight: .semibold))
                            .tracking(2.5)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color(red: 24/255, green: 24/255, blue: 27/255))
                            .clipShape(Capsule())
                            .shadow(color: Color.black.opacity(0.12), radius: 10, y: 5)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 30)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.gray)
                }
            }
            .onAppear {
                let currentChest = appState.userMetrics["chestCm"] ?? 0
                let currentWaist = appState.userMetrics["waistCm"] ?? 0
                let currentHips = appState.userMetrics["hipsCm"] ?? 0
                
                chestInches = String(format: "%.1f", currentChest / 2.54)
                waistInches = String(format: "%.1f", currentWaist / 2.54)
                hipsInches = String(format: "%.1f", currentHips / 2.54)
            }
        }
    }
    
    private func saveChanges() {
        if let cVal = Double(chestInches), let wVal = Double(waistInches), let hVal = Double(hipsInches) {
            var updated = appState.userMetrics
            updated["chestCm"] = cVal * 2.54
            updated["waistCm"] = wVal * 2.54
            updated["hipsCm"] = hVal * 2.54
            
            appState.updateMetricsDirectly(updated)
            dismiss()
        }
    }
}

struct MetricInputRow: View {
    let label: String
    @Binding var value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.5)
                .foregroundColor(Color(red: 113/255, green: 113/255, blue: 122/255))
                .padding(.leading, 8)
            
            TextField("", text: $value)
                .keyboardType(.decimalPad)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.white)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color(red: 228/255, green: 228/255, blue: 231/255), lineWidth: 1))
                .foregroundColor(Color(red: 24/255, green: 24/255, blue: 27/255))
                .accentColor(Color(red: 24/255, green: 24/255, blue: 27/255))
        }
    }
}
