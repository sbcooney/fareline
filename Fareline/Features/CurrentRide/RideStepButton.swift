import SwiftUI

/// Takes the driver's next step on a ride, showing progress while the service responds.
struct RideStepButton: View {
    @Environment(DriverModel.self) private var model

    let ride: Ride

    var body: some View {
        if let title = ride.status.nextStepTitle {
            Button(action: takeNextStep) {
                // The title stays in the layout during a request, so the button's size doesn't change.
                Text(title)
                    .opacity(model.isPerformingAction ? 0 : 1)
                    .overlay {
                        if model.isPerformingAction {
                            ProgressView()
                        }
                    }
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            // In dark mode the brand color is light, so white text on it wouldn't be readable.
            .foregroundStyle(.textOnBrand)
            .controlSize(.large)
            .disabled(model.isPerformingAction)
            // VoiceOver can skip fully transparent text, so the name is set explicitly.
            .accessibilityLabel(Text(title))
            .accessibilityValue(model.isPerformingAction ? Text("Updating") : Text(""))
        }
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
