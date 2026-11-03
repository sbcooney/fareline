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
                    Text(ride.cancelledBy?.cancellationTitle ?? ride.status.title)
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
    @Previewable @State var model: DriverModel?
    let ride = {
        var ride = MockRideData.makeRide(sequence: 0, requestedAt: .now.addingTimeInterval(-900))
        try? ride.apply(.driverAssigned(driverID: MockRideData.driver.id))
        try? ride.apply(.driverArrived)
        try? ride.apply(.tripStarted)
        try? ride.apply(.tripCompleted(date: .now))
        return ride
    }()

    NavigationStack {
        if let model {
            PastRideDetailView(rideID: ride.id)
                .environment(model)
        }
    }
    .task {
        // The service loads past rides from a store, so the preview saves one to a temporary file first.
        let pastRideStore = PastRideStore(fileURL: .temporaryDirectory.appending(path: "PastRideDetailPreview.json"))
        try? pastRideStore.save([ride])
        let newModel = DriverModel(service: MockRideService(pastRideStore: pastRideStore))
        model = newModel
        await newModel.start()
    }
}
