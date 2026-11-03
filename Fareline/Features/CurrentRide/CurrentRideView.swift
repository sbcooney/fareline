import SwiftUI

/// Shows the ride the driver is on, with the one step they take next.
struct CurrentRideView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let ride: Ride

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
        .safeAreaInset(edge: .bottom) {
            VStack {
                RideStepButton(ride: ride)
                CancelRideButton(ride: ride)
            }
            .padding()
                // The list scrolls behind the button at large text sizes.
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
