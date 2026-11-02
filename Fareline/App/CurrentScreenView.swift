import SwiftUI

/// Chooses the screen that matches the driver's current session.
struct CurrentScreenView: View {
    /// The latest session, or `nil` until the first one arrives.
    let session: DriverSession?

    var body: some View {
        if let session {
            if let offer = session.pendingOffer {
                OfferView(offer: offer)
            } else {
                AvailabilityView(availability: session.driver.availability)
            }
        } else {
            ProgressView("Connecting")
        }
    }
}
