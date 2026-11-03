import SwiftUI

/// Lists the driver's past rides, newest first, each linking to its details.
struct PastRidesView: View {
    @Environment(DriverModel.self) private var model

    var body: some View {
        let rides = model.session?.pastRides ?? []

        Group {
            if rides.isEmpty {
                ContentUnavailableView(
                    "No Past Rides",
                    systemImage: "clock",
                    description: Text("Rides you finish will appear here.")
                )
            } else {
                List(rides) { ride in
                    NavigationLink(value: AppDestination.pastRide(ride.id)) {
                        PastRideRow(ride: ride)
                    }
                }
            }
        }
        .navigationTitle("Past Rides")
    }
}

#Preview {
    @Previewable @State var model = DriverModel(service: MockRideService())

    NavigationStack {
        PastRidesView()
    }
    .environment(model)
    .task {
        await model.start()
    }
}
