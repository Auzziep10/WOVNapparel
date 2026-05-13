import SwiftUI

@available(iOS 17.0, *)
struct OccasionSelectionView: View {
    @EnvironmentObject var appState: AppFlowState
    
    let occasions = ["Corporate", "Wedding", "Night Out", "Gym", "Mixer"]
    
    // We use a custom scroll state to track the center element
    @State private var scrollOffset: CGFloat = 0
    @State private var selectedIndex: Int = 2 // Default to center
    
    var body: some View {
        ZStack {
            // Background Image (Blurred)
            if let bodyImage = appState.bodyImage {
                Image(uiImage: bodyImage)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .blur(radius: 40)
                    .overlay(Color.white.opacity(0.3)) // Light overlay to ensure black text is readable
            } else {
                Color(white: 0.9).ignoresSafeArea()
            }
            
            // Logo Top Left
            VStack {
                HStack {
                    Image("wovn-logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100)
                        .padding(.leading, 24)
                        .padding(.top, 20)
                    Spacer()
                }
                Spacer()
            }
            
            // Custom Wheel Picker
            GeometryReader { geometry in
                let midY = geometry.size.height / 2
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Top padding to allow first item to hit center
                        Color.clear.frame(height: midY - 40)
                        
                        ForEach(0..<occasions.count, id: \.self) { index in
                            GeometryReader { itemGeometry in
                                let itemMidY = itemGeometry.frame(in: .global).midY
                                let distance = abs(midY - itemMidY)
                                let isSelected = distance < 40 // Close to center
                                
                                Text(occasions[index])
                                    // Elegant Serif styling to match WOVN Garment Catalog
                                    .font(.system(size: isSelected ? 48 : 36, weight: isSelected ? .medium : .light, design: .serif))
                                    .italic(isSelected)
                                    .foregroundColor(isSelected ? .black : .black.opacity(0.3))
                                    .frame(maxWidth: .infinity)
                                    .scaleEffect(isSelected ? 1.0 : 0.8)
                                    .animation(.easeOut(duration: 0.2), value: isSelected)
                                    .onChange(of: isSelected) { newlySelected in
                                        if newlySelected {
                                            let generator = UISelectionFeedbackGenerator()
                                            generator.selectionChanged()
                                            self.selectedIndex = index
                                        }
                                    }
                            }
                            .frame(height: 80)
                        }
                        
                        // Bottom padding to allow last item to hit center
                        Color.clear.frame(height: midY - 40)
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned) // Requires iOS 17
            }
            .ignoresSafeArea()
            
            // Next Button
            VStack {
                Spacer()
                Button(action: {
                    let selectedOccasion = occasions[selectedIndex]
                    // We don't have tech packs fetched yet, so we just mock routing for now
                    appState.currentRoute = .tryOn(techPackId: "mock_\(selectedOccasion)")
                }) {
                    Text("Select Occasion")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .cornerRadius(30)
                        .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.light)
    }
}
