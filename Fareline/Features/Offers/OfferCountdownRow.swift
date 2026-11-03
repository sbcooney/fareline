import SwiftUI

/// Shows the time left to respond to an offer.
struct OfferCountdownRow: View {
    let expiresAt: Date

    var body: some View {
        // The visible countdown updates itself, but VoiceOver needs a value it can read, so the row is redrawn
        // each second to give it one.
        TimelineView(.periodic(from: .now, by: 1)) { context in
            LabeledContent("Time Left") {
                // A range can't start after it ends, and this can draw just after the offer's expiry, before the
                // service's update arrives.
                Text(timerInterval: min(context.date, expiresAt)...expiresAt, countsDown: true)
                    .monospacedDigit()
                    .bold()
                    .foregroundStyle(.primary)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Time Left")
            .accessibilityValue(spokenTimeLeft(at: context.date))
        }
    }

    /// The time left in words, such as "27 seconds", rather than the "0:27" a screen reader would read out.
    private func spokenTimeLeft(at date: Date) -> String {
        let seconds = max(0, expiresAt.timeIntervalSince(date).rounded(.up))
        return Duration.seconds(seconds).formatted(.units(allowed: [.minutes, .seconds], width: .wide))
    }
}

#Preview {
    List {
        OfferCountdownRow(expiresAt: .now.addingTimeInterval(30))
    }
}
