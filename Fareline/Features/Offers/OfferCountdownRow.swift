import SwiftUI

/// Shows the time left to respond to an offer.
struct OfferCountdownRow: View {
    let expiresAt: Date

    var body: some View {
        LabeledContent("Time Left") {
            // The range can't end before it starts, and the app can draw this just after the offer's expiry,
            // before the service's update arrives.
            Text(timerInterval: Date.now...max(Date.now, expiresAt), countsDown: true)
                .monospacedDigit()
                .bold()
                .foregroundStyle(.primary)
        }
    }
}

#Preview {
    List {
        OfferCountdownRow(expiresAt: .now.addingTimeInterval(30))
    }
}
