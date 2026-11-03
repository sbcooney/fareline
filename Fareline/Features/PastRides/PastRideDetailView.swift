import SwiftUI

/// Shows everything about one past ride.
///
/// It takes the ride's ID rather than the ride, so it reads the ride from the model and shows that it's
/// missing if the model no longer has it, rather than a stale copy.
struct PastRideDetailView: View {
    @Environment(DriverModel.self) private var model

    let rideID: Ride.ID

    var body: some View {
        Group {
            if let ride = model.pastRide(id: rideID) {
                details(of: ride)
            } else {
                ContentUnavailableView("Ride Not Available", systemImage: "exclamationmark.triangle")
            }
        }
        .navigationTitle("Ride Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func details(of ride: Ride) -> some View {
        List {
            Section {
                LabeledContent("Status") {
                    Text(ride.status.title)
                }
                LabeledContent("Rider", value: ride.rider.name.formatted())
                // A cancelled ride earned nothing, so it has no fare to show.
                if ride.status != .cancelled {
                    LabeledContent(
                        "Fare",
                        value: ride.fare.amount,
                        format: .currency(code: ride.fare.currencyCode)
                    )
                }
            }
            Section {
                PlaceRow(title: "Pickup", place: ride.pickup)
                PlaceRow(title: "Drop-off", place: ride.dropoff)
            }
            Section {
                LabeledContent("Requested") {
                    Text(ride.requestedAt, format: .dateTime)
                }
                if let endedAt = ride.endedAt {
                    LabeledContent("Ended") {
                        Text(endedAt, format: .dateTime)
                    }
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var model = DriverModel(service: MockRideService())

    NavigationStack {
        PastRideDetailView(rideID: UUID())
    }
    .environment(model)
}
