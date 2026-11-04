import SwiftUI

/// Changes the driver's status, showing progress while the service responds.
struct AvailabilityButton: View {
    @Environment(DriverModel.self) private var model

    let availability: DriverAvailability

    var body: some View {
        PrimaryActionButton(
            title: availability.actionTitle,
            isInProgress: model.isPerformingAction,
            action: changeAvailability
        )
        .disabled(model.canChangeAvailability == false)
        // Go Offline appears where Accept was when an offer ends, and where Go Online was after going online.
        .ignoresTapsBriefly(after: availability)
    }

    /// Requests the change this button's title describes.
    ///
    /// This uses the status the button was drawn with rather than the latest one, so that a tap can
    /// never do the opposite of what the driver read.
    private func changeAvailability() {
        Task {
            switch availability {
            case .offline:
                await model.goOnline()
            case .available:
                await model.goOffline()
            case .onRide:
                break
            }
        }
    }
}
