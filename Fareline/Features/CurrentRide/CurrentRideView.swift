import SwiftUI

/// Shows the ride the driver is on, with the one step they take next.
struct CurrentRideView: View {
    @Environment(DriverModel.self) private var model
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let ride: Ride

    @State private var isShowingHelp = false

    var body: some View {
        List {
            Section {
                LabeledContent("Rider", value: ride.rider.name.formatted())
                LabeledContent(
                    "Estimated Fare",
                    value: ride.fare.amount,
                    format: .currency(code: ride.fare.currencyCode)
                )
            }
            Section {
                PlaceRow(title: "Pickup", place: ride.pickup)
                PlaceRow(title: "Drop-off", place: ride.dropoff)
            }
        }
        .navigationTitle(Text(ride.status.title))
        // A large title truncates at accessibility text sizes, and the smaller inline title fits.
        .navigationBarTitleDisplayMode(dynamicTypeSize.isAccessibilitySize ? .inline : .automatic)
        // Cancelling is rare and can't be undone, so it's behind a button up here, away from the step button.
        .toolbar {
            RideOptionsButton(ride: ride)
        }
        .safeAreaInset(edge: .bottom) {
            VStack {
                RideStepButton(ride: ride)
                // Waiting is when a driver most needs to reach the rider, so help shows only at pickup for now.
                if ride.status == .driverArrived {
                    // Bordered under the filled step button, so the next step stays the main action.
                    Button {
                        isShowingHelp = true
                    } label: {
                        Text("Get Help")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    // The brand color on the bordered button's light fill fails contrast in light mode.
                    .foregroundStyle(.primary)
                    .controlSize(.large)
                    // The sheet holds Cancel Ride, so it's unavailable during a request, as Ride Options is.
                    .disabled(model.canTakeRideStep == false)
                    .sheet(isPresented: $isShowingHelp) {
                        RideHelpSheet(ride: ride)
                    }
                }
            }
            .padding()
            // The list scrolls behind the buttons at large text sizes.
            .background(.bar)
        }
    }
}

#Preview {
    @Previewable @State var model = DriverModel(service: MockRideService())
    let ride = {
        var ride = MockRideData.makeRide(sequence: 0, requestedAt: .now)
        try? ride.apply(.driverAssigned(driverID: MockRideData.driver.id))
        return ride
    }()

    NavigationStack {
        CurrentRideView(ride: ride)
    }
    .environment(model)
}
