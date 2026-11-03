import SwiftUI

/// One rider in the waiting list: their trip, the fare, how long they've waited, and a button to take the ride.
struct WaitingRideRow: View {
    @Environment(DriverModel.self) private var model

    let ride: Ride

    /// Whether the driver can take a ride now. The list decides this once for every row, so a row doesn't redraw
    /// each time the session changes.
    let canTake: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading) {
                Text("\(ride.pickup.name) to \(ride.dropoff.name)")
                    .font(.headline)
                Text(ride.fare.amount, format: .currency(code: ride.fare.currencyCode))
                // The wait keeps counting while the list is open, redrawn as each minute passes.
                TimelineView(.everyMinute) { context in
                    Text(ride.waitDescription(at: context.date))
                        .foregroundStyle(.textSecondary)
                }
            }
            // The button stays separate, so VoiceOver reads the ride as one element and the button as another.
            .accessibilityElement(children: .combine)

            Button("Take Ride", action: takeRide)
                .buttonStyle(.bordered)
                .disabled(canTake == false)
        }
        .padding(.vertical, 4)
    }

    private func takeRide() {
        Task { await model.claimRide(rideID: ride.id) }
    }
}

#Preview {
    @Previewable @State var model = DriverModel(service: MockRideService())
    let ride = MockRideData.makeRide(sequence: 0, requestedAt: .now.addingTimeInterval(-300))

    List {
        WaitingRideRow(ride: ride, canTake: true)
        WaitingRideRow(ride: ride, canTake: false)
    }
    .environment(model)
}
