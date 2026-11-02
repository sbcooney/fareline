import SwiftUI

/// Shows the time left to respond to an offer.
struct OfferCountdownRow: View {
    let expiresAt: Date

    var body: some View {
        LabeledContent("Time Left") {
            // A range can't start after it ends, and this can draw just after the offer's expiry, before the
            // service's update arrives. Reading the clock once keeps that true even if the clock changes.
            Text(timerInterval: min(Date.now, expiresAt)...expiresAt, countsDown: true)
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
