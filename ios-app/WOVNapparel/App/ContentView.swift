import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "camera.macro")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("WOVN apparel iOS System Ready")
                .font(.headline)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
