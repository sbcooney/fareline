import SwiftUI

/// Shows the time left to respond to an offer.
struct OfferCountdownRow: View {
    let expiresAt: Date

    var body: some View {
        // The row redraws each second, so the visible time and VoiceOver's value come from the same clock and
        // can't disagree.
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let timeLeft = timeLeft(at: context.date)

            LabeledContent("Time Left") {
                Text(timeLeft.formatted(.time(pattern: .minuteSecond)))
                    .monospacedDigit()
                    .bold()
                    .foregroundStyle(.primary)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Time Left")
            // In words, such as "27 seconds", rather than the "0:27" a screen reader would read out.
            .accessibilityValue(timeLeft.formatted(.units(allowed: [.minutes, .seconds], width: .wide)))
        }
    }

    /// The whole seconds left, never below zero, as this can draw just after the offer's expiry, before the
    /// service's update arrives.
    private func timeLeft(at date: Date) -> Duration {
        .seconds(max(0, expiresAt.timeIntervalSince(date).rounded(.up)))
    }
}

#Preview {
    List {
        OfferCountdownRow(expiresAt: .now.addingTimeInterval(30))
    }
}
