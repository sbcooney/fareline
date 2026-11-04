import SwiftUI

/// Takes the driver's next step on a ride, showing progress while the service responds.
struct RideStepButton: View {
    @Environment(DriverModel.self) private var model

    let ride: Ride

    /// Whether the button has been showing its step long enough to take a tap. See ``ignoreTapsBriefly()``.
    @State private var isReady = false

    private var isDisabled: Bool {
        model.isPerformingAction || isReady == false
    }

    var body: some View {
        if let title = ride.status.nextStepTitle {
            Button(action: takeNextStep) {
                // The title stays in the layout during a request, so the button's size doesn't change.
                Text(title)
                    .opacity(isTakingStep ? 0 : 1)
                    .overlay {
                        if isTakingStep {
                            ProgressView()
                        }
                    }
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            // In dark mode the brand color is light, so white text on it wouldn't be readable. A disabled button
            // keeps the system's dimmed label, so it doesn't look tappable.
            .foregroundStyle(isDisabled ? AnyShapeStyle(.tertiary) : AnyShapeStyle(.textOnBrand))
            .controlSize(.large)
            .disabled(isDisabled)
            .task(id: ride.status, ignoreTapsBriefly)
            // VoiceOver can skip fully transparent text, so the name is set explicitly.
            .accessibilityLabel(Text(title))
            .accessibilityValue(isTakingStep ? Text("Updating") : Text(""))
        }
    }

    /// Offline, a step shows at once, so the next step's title appears under the driver's finger, and a double tap
    /// would take a step they never saw. Online, the request in progress covers that gap. `AvailabilityButton` uses
    /// the same delay.
    private func ignoreTapsBriefly() async {
        isReady = false
        do {
            try await Task.sleep(for: .seconds(0.75))
        } catch {
            // A cancelled wait belongs to a step that's gone, so it mustn't ready the button for the next one.
            return
        }
        isReady = true
    }

    /// Whether the request in progress is this button's step. Cancelling shows its progress on the Ride Options
    /// button instead, while this button is only disabled.
    private var isTakingStep: Bool {
        model.isPerformingAction && model.isCancellingRide == false
    }

    /// Requests the step this button's title describes.
    ///
    /// This uses the status the button was drawn with rather than the latest one, so a tap can never
    /// skip a step the driver didn't see.
    private func takeNextStep() {
        Task {
            switch ride.status {
            case .driverEnRoute:
                await model.markArrived(rideID: ride.id)
            case .driverArrived:
                await model.startTrip(rideID: ride.id)
            case .inProgress:
                await model.completeTrip(rideID: ride.id)
            case .awaitingDriver, .completed, .cancelled:
                break
            }
        }
    }
}
