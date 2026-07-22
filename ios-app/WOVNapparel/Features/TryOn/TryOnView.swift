import SwiftUI

struct TryOnView: View {
    @EnvironmentObject var appState: AppFlowState
    
    let occasion: String
    
    // Gestures State for Image Adjustments (Pan and Zoom)
    @State private var offset: CGSize = .zero
    @State private var dragOffset: CGSize = .zero
    @State private var scale: CGFloat = 1.0
    @State private var magnification: CGFloat = 1.0
    
    @State private var expandedGarmentId: String? = nil
    @State private var recommendedSize: String = ""
    
    private var groupedGarments: [[Garment]] {
        var groups: [String: [Garment]] = [:]
        var orderedBaseIds: [String] = []
        
        for garment in appState.recommendedGarments {
            let base = garment.baseId
            if groups[base] == nil {
                groups[base] = []
                orderedBaseIds.append(base)
            }
            groups[base]?.append(garment)
        }
        
        return orderedBaseIds.compactMap { groups[$0] }
    }
    
    private var currentOffset: CGSize {
        CGSize(
            width: offset.width + dragOffset.width,
            height: offset.height + dragOffset.height
        )
    }
    
    private var currentScale: CGFloat {
        max(0.5, min(scale * magnification, 4.0))
    }
    
    var body: some View {
        ZStack {
            // 1. Full-Bleed Background Layer constrained by GeometryReader
            GeometryReader { geo in
                Group {
                    if let finalURL = appState.generatedImageURL {
                        AsyncImage(url: finalURL) { phase in
                            switch phase {
                            case .empty:
                                Color(red: 244/255, green: 244/255, blue: 245/255)
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                            case .failure:
                                Color(red: 244/255, green: 244/255, blue: 245/255)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    } else if let bodyImage = appState.bodyImage {
                        Image(uiImage: bodyImage)
                            .resizable()
                            .scaledToFill()
                    } else if let remoteBody = appState.remoteBodyURL {
                        AsyncImage(url: URL(string: remoteBody)) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                Color(red: 244/255, green: 244/255, blue: 245/255)
                            }
                        }
                    } else if let faceImage = appState.faceImage {
                        Image(uiImage: faceImage)
                            .resizable()
                            .scaledToFill()
                    } else if let remoteFace = appState.remoteFaceURL {
                        AsyncImage(url: URL(string: remoteFace)) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                Color(red: 244/255, green: 244/255, blue: 245/255)
                            }
                        }
                    } else {
                        Color(red: 244/255, green: 244/255, blue: 245/255)
                    }
                }
                .opacity(appState.isSynthesizing ? 0.6 : 1.0)
                .animation(.easeInOut, value: appState.isSynthesizing)
                .scaleEffect(currentScale)
                .offset(currentOffset)
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            dragOffset = value.translation
                        }
                        .onEnded { value in
                            offset.width += value.translation.width
                            offset.height += value.translation.height
                            dragOffset = .zero
                        }
                )
                .simultaneousGesture(
                    MagnificationGesture()
                        .onChanged { value in
                            magnification = value
                        }
                        .onEnded { value in
                            scale = max(0.5, min(scale * value, 4.0))
                            magnification = 1.0
                        }
                )
                .simultaneousGesture(
                    TapGesture(count: 2)
                        .onEnded {
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                                offset = .zero
                                dragOffset = .zero
                                scale = 1.0
                                magnification = 1.0
                            }
                        }
                )
            }
            .ignoresSafeArea()
            
            // 2. Global Loading Spinner (Only for initial load, or when synthesizing)
            if appState.isSynthesizing {
                VStack(spacing: 32) {
                    Text("\(appState.synthesisProgress)%")
                        .font(.system(size: 64, weight: .light, design: .serif))
                        .foregroundColor(Color(red: 24/255, green: 24/255, blue: 27/255))
                    
                    VStack(spacing: 8) {
                        Text("Synthesizing Style...")
                            .font(.system(size: 24, weight: .regular, design: .serif))
                        
                        Text("Running garment mapping...")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                }
            }
            
            // 3. UI Overlay
            VStack {
                // Top Logo
                HStack {
                    Image("wovn-logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100)
                        .colorMultiply(.black) // Force black if needed, or leave native
                    Spacer()
                }
                .padding(.leading, 24)
                .padding(.top, 20)
                
                Spacer()
                
                // Left Rolodex Menu
                HStack {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 20) {
                            ForEach(groupedGarments, id: \.first?.baseId) { group in
                                if let mainGarment = group.first {
                                    let baseId = mainGarment.baseId
                                    let isExpanded = expandedGarmentId == baseId
                                    
                                    HStack(spacing: 12) {
                                        Button(action: {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                                if group.count > 1 {
                                                    if isExpanded {
                                                        expandedGarmentId = nil
                                                    } else {
                                                        expandedGarmentId = baseId
                                                    }
                                                } else {
                                                    if appState.selectedGarmentId != mainGarment.id && !appState.isSynthesizing {
                                                        let generator = UIImpactFeedbackGenerator(style: .medium)
                                                        generator.impactOccurred()
                                                        appState.triggerSynthesis(occasion: occasion, garmentId: mainGarment.id)
                                                    }
                                                }
                                            }
                                        }) {
                                            ZStack {
                                                Circle()
                                                    .fill(Color.white)
                                                    .frame(width: 60, height: 60)
                                                    .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
                                                
                                                let activeThumbnail = group.first(where: { $0.id == appState.selectedGarmentId })?.thumbnail ?? mainGarment.thumbnail
                                                
                                                AsyncImage(url: URL(string: activeThumbnail)) { image in
                                                    image.resizable().scaledToFill()
                                                } placeholder: {
                                                    Color.gray.opacity(0.2)
                                                }
                                                .frame(width: 50, height: 50)
                                                .clipShape(Circle())
                                                
                                                if !isExpanded && appState.isSynthesizing && group.contains(where: { $0.id == appState.selectedGarmentId }) {
                                                    Circle()
                                                        .fill(Color.black.opacity(0.6))
                                                        .frame(width: 60, height: 60)
                                                    
                                                    Text("\(appState.synthesisProgress)%")
                                                        .font(.system(size: 14, weight: .bold))
                                                        .foregroundColor(.white)
                                                }
                                                
                                                if group.count > 1 && !isExpanded {
                                                    VStack {
                                                        Spacer()
                                                        HStack {
                                                            Spacer()
                                                            Circle()
                                                                .fill(Color.black)
                                                                .frame(width: 14, height: 14)
                                                                .overlay(
                                                                    Image(systemName: "plus")
                                                                        .font(.system(size: 8, weight: .bold))
                                                                        .foregroundColor(.white)
                                                                )
                                                                .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                                                                .shadow(radius: 2)
                                                        }
                                                    }
                                                    .frame(width: 60, height: 60)
                                                }
                                                
                                                let isAnySelected = group.contains(where: { $0.id == appState.selectedGarmentId })
                                                if isAnySelected && !isExpanded {
                                                    Circle()
                                                        .stroke(Color.black, lineWidth: 2)
                                                        .frame(width: 66, height: 66)
                                                }
                                            }
                                        }
                                        
                                        if isExpanded {
                                            HStack(spacing: 8) {
                                                ForEach(group) { colorGarment in
                                                    Button(action: {
                                                        if appState.selectedGarmentId != colorGarment.id && !appState.isSynthesizing {
                                                            let generator = UIImpactFeedbackGenerator(style: .medium)
                                                            generator.impactOccurred()
                                                            appState.triggerSynthesis(occasion: occasion, garmentId: colorGarment.id)
                                                        }
                                                    }) {
                                                        ZStack {
                                                            Circle()
                                                                .fill(Color.white)
                                                                .frame(width: 50, height: 50)
                                                                .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
                                                            
                                                            AsyncImage(url: URL(string: colorGarment.thumbnail)) { image in
                                                                image.resizable().scaledToFill()
                                                            } placeholder: {
                                                                Color.gray.opacity(0.2)
                                                            }
                                                            .frame(width: 42, height: 42)
                                                            .clipShape(Circle())
                                                            
                                                            if appState.isSynthesizing && appState.selectedGarmentId == colorGarment.id {
                                                                Circle()
                                                                    .fill(Color.black.opacity(0.6))
                                                                    .frame(width: 50, height: 50)
                                                                
                                                                Text("\(appState.synthesisProgress)%")
                                                                    .font(.system(size: 11, weight: .bold))
                                                                    .foregroundColor(.white)
                                                            }
                                                            
                                                            if appState.selectedGarmentId == colorGarment.id {
                                                                Circle()
                                                                    .stroke(Color.black, lineWidth: 2)
                                                                    .frame(width: 54, height: 54)
                                                            }
                                                        }
                                                    }
                                                    .transition(.asymmetric(
                                                        insertion: .scale.combined(with: .opacity).combined(with: .move(edge: .leading)),
                                                        removal: .scale.combined(with: .opacity).combined(with: .move(edge: .leading))
                                                    ))
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 40)
                    }
                    .padding(.leading, 24)
                    
                    Spacer()
                }
                
                Spacer()
                
                // Recommended Size Overlay Pill
                if !recommendedSize.isEmpty {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(.black)
                        
                        Text(recommendedSize)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.black)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
                    .padding(.bottom, 12)
                }
                
                // Bottom Done Button
                Button(action: {
                    appState.currentRoute = .profileReview
                }) {
                    Text("SAVE & EXIT")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(2)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.black)
                        .cornerRadius(30)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .task(id: appState.selectedGarmentId) {
            if let gId = appState.selectedGarmentId {
                do {
                    let size = try await appState.fetchSizeRecommendation(techPackId: gId)
                    self.recommendedSize = size
                } catch {
                    self.recommendedSize = "Size: Unknown"
                }
            } else {
                self.recommendedSize = ""
            }
        }
    }
}
