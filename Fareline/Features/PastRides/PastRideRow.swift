import SwiftUI

/// Summarizes one past ride: its route, when it ended, and its fare or that it was cancelled.
struct PastRideRow: View {
    let ride: Ride

    var body: some View {
        VStack(alignment: .leading) {
            Text("\(ride.pickup.name) to \(ride.dropoff.name)")
                .font(.headline)
            if let endedAt = ride.endedAt {
                Text(endedAt, format: .dateTime.month().day().hour().minute())
                    .foregroundStyle(.textSecondary)
            }
            // A cancelled ride earned nothing, so it shows its status instead of a fare.
            if ride.status == .cancelled {
                Text(ride.status.title)
                    .foregroundStyle(.textSecondary)
            } else {
                Text(ride.fare.amount, format: .currency(code: ride.fare.currencyCode))
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    let ride = {
        var ride = MockRideData.makeRide(sequence: 0, requestedAt: .now)
        try? ride.apply(.driverAssigned(driverID: MockRideData.driver.id))
        try? ride.apply(.cancelled(by: .rider, date: .now))
        return ride
    }()

    List {
        PastRideRow(ride: ride)
    }
}
