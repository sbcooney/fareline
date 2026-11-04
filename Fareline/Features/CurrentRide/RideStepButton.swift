import SwiftUI

/// Takes the driver's next step on a ride, showing progress while the service responds.
struct RideStepButton: View {
    @Environment(DriverModel.self) private var model

    let ride: Ride

    var body: some View {
        if let title = ride.status.nextStepTitle {
            PrimaryActionButton(title: title, isInProgress: isTakingStep, action: takeNextStep)
                .disabled(model.canTakeRideStep == false)
                // Offline, a step shows at once, so the next step's title appears under the driver's finger, and a
                // double tap would take a step they never saw. Online, the request in progress covers that gap.
                .ignoresTapsBriefly(after: ride.status)
        }
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
