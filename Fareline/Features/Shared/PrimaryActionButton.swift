import SwiftUI

/// The filled button for a screen's main action, such as Go Online or Start Trip, with a progress state.
///
/// It dims its text whenever it's disabled, whether by its caller or by a modifier such as
/// `ignoresTapsBriefly(after:)`, because it reads that from the environment.
struct PrimaryActionButton: View {
    @Environment(\.isEnabled) private var isEnabled

    let title: LocalizedStringResource

    /// Whether to show progress in place of the title, while the action's request is in progress.
    var isInProgress = false

    let action: () -> Void

    var body: some View {
        Button(action: action) {
            // The title stays in the layout during a request, so the button's size doesn't change.
            Text(title)
                .opacity(isInProgress ? 0 : 1)
                .overlay {
                    if isInProgress {
                        ProgressView()
                    }
                }
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        // In dark mode the brand color is light, so white text on it wouldn't be readable. A disabled button
        // keeps the system's dimmed label, so it doesn't look tappable.
        .foregroundStyle(isEnabled ? AnyShapeStyle(.textOnBrand) : AnyShapeStyle(.tertiary))
        .controlSize(.large)
        // VoiceOver can skip fully transparent text, so the name is set explicitly.
        .accessibilityLabel(Text(title))
        .accessibilityValue(isInProgress ? Text("Updating") : Text(""))
    }
}

#Preview {
    VStack {
        PrimaryActionButton(title: "Go Online", action: {})
        PrimaryActionButton(title: "Go Online", isInProgress: true, action: {})
        PrimaryActionButton(title: "Go Online", action: {})
            .disabled(true)
    }
    .padding()
}
