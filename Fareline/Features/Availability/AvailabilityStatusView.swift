import SwiftUI

/// Shows the driver's current status and what it means for them.
struct AvailabilityStatusView: View {
    let availability: DriverAvailability

    var body: some View {
        VStack {
            Image(systemName: availability.symbolName)
                .font(.largeTitle)
                .foregroundStyle(availability.tint)
                .accessibilityHidden(true)
            Text(availability.title)
                .font(.title)
                .bold()
            Text(availability.explanation)
                .foregroundStyle(.textSecondary)
        }
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    AvailabilityStatusView(availability: .available)
}
