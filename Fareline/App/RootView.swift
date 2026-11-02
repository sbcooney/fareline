import SwiftUI

/// The app's top-level view.
///
/// This is a placeholder until the driver flow is built.
struct RootView: View {
    var body: some View {
        ContentUnavailableView(
            "Fareline",
            systemImage: "car.fill",
            description: Text("The driver flow is coming soon.")
        )
    }
}

#Preview {
    RootView()
}
