import SwiftUI

/// Lists the riders that no driver has taken, longest wait first, so the driver can take one themselves.
struct WaitingRidersView: View {
    @Environment(DriverModel.self) private var model

    var body: some View {
        let rides = model.session?.waitingRides ?? []
        let availability = model.session?.driver.availability
        let canTake = model.canClaimRide

        Group {
            if rides.isEmpty {
                ContentUnavailableView(
                    "No Riders Waiting",
                    systemImage: "person.2",
                    description: Text("Riders that no driver has taken will appear here.")
                )
            } else {
                List {
                    Section {
                        ForEach(rides) { ride in
                            WaitingRideRow(ride: ride, canTake: canTake)
                        }
                    } footer: {
                        // Offline, the list shows what was last received, and taking a ride waits for the connection.
                        if model.isOffline {
                            Text("Taking a ride needs a connection.")
                        } else if availability == .offline {
                            // The list still shows while the driver is offline, so they can decide whether to go
                            // online.
                            Text("Go online to take a ride.")
                        }
                    }
                }
            }
        }
        .navigationTitle("Waiting Riders")
    }
}

#Preview {
    @Previewable @State var model = DriverModel(
        service: MockRideService(waitingRides: MockRideData.passedOverRides(at: .now))
    )

    NavigationStack {
        WaitingRidersView()
    }
    .environment(model)
    .task {
        await model.start()
    }
}
