import SwiftUI

/// Opens the ride's less common actions, kept up here so they stay away from the driver's next step.
struct RideOptionsButton: View {
    @Environment(DriverModel.self) private var model

    let ride: Ride

    @State private var isShowingOptions = false

    var body: some View {
        if ride.status.canBeCancelled(by: .driver) {
            Button {
                isShowingOptions = true
            } label: {
                if model.isCancellingRide {
                    ProgressView()
                } else {
                    Label("Ride Options", systemImage: "ellipsis")
                }
            }
            .disabled(model.canTakeRideStep == false)
            // The progress view replaces the label while cancelling, so the name is set explicitly.
            .accessibilityLabel(Text("Ride Options"))
            .accessibilityValue(model.isCancellingRide ? Text("Updating") : Text(""))
            .sheet(isPresented: $isShowingOptions) {
                RideOptionsSheet(ride: ride)
            }
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
        Text(verbatim: "Current ride")
            .toolbar {
                RideOptionsButton(ride: ride)
            }
    }
    .environment(model)
}
