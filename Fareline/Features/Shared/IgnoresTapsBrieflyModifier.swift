import SwiftUI

/// Disables a control for a moment each time a value changes, so a tap meant for the control that was there before
/// can't trigger the new one.
///
/// Controls that replace each other in the same place use it: Accept appears where Go Offline was, Go Offline where
/// Go Online was, and offline, the next ride step's title appears under the driver's finger.
struct IgnoresTapsBrieflyModifier<Value: Equatable>: ViewModifier {
    let value: Value

    @State private var isReady = false

    func body(content: Content) -> some View {
        content
            .disabled(isReady == false)
            .task(id: value, waitBeforeTakingTaps)
    }

    private func waitBeforeTakingTaps() async {
        isReady = false
        do {
            try await Task.sleep(for: .seconds(0.75))
        } catch {
            // A cancelled wait belongs to a value that's gone, so it mustn't ready the control for the next one.
            return
        }
        isReady = true
    }
}

extension View {
    /// Ignores taps for 0.75 seconds after the view appears, and each time the value changes.
    func ignoresTapsBriefly(after value: some Equatable) -> some View {
        modifier(IgnoresTapsBrieflyModifier(value: value))
    }
}
