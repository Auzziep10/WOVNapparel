import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Image(systemName: "cube.transparent")
                    .imageScale(.large)
                    .font(.system(size: 60))
                    .foregroundStyle(.tint)
                    .padding(.bottom, 20)
                
                Text("WOVN apparel")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Spatial Sizing Engine Ready")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 50)
                
                NavigationLink(destination: CameraView()) {
                    Text("Initialize 3D Scan")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
