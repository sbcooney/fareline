import SwiftUI

/// Lists the driver's past rides, newest first, each linking to its details, filtered to completed rides by default.
struct PastRidesView: View {
    @Environment(DriverModel.self) private var model

    /// Which rides show. It lasts while the driver views a ride's details, and resets to Completed each time Past
    /// Rides opens, so the screen always opens the same way.
    @State private var filter = PastRideFilter.completed

    var body: some View {
        let rides = model.session?.pastRides ?? []
        let shownRides = rides.filter(filter.matches)

        Group {
            if rides.isEmpty {
                ContentUnavailableView(
                    "No Past Rides",
                    systemImage: "clock",
                    description: Text("Rides you finish will appear here.")
                )
            } else if shownRides.isEmpty {
                ContentUnavailableView {
                    Label(filter.noMatchTitle, systemImage: "line.3.horizontal.decrease.circle")
                } actions: {
                    Button("Show All Rides", action: showAllRides)
                }
            } else {
                List {
                    Section {
                        ForEach(shownRides) { ride in
                            NavigationLink(value: AppDestination.pastRide(ride.id)) {
                                PastRideRow(ride: ride)
                            }
                        }
                    } header: {
                        // The count shows that some rides are hidden, which VoiceOver users also hear on a change.
                        if filter != .all {
                            Text(PastRideFilter.countDescription(showing: shownRides.count, of: rides.count))
                        }
                    }
                }
            }
        }
        .navigationTitle("Past Rides")
        .toolbar {
            if rides.isEmpty == false {
                Menu {
                    Picker("Show", selection: $filter) {
                        ForEach(PastRideFilter.allCases, id: \.self) { choice in
                            Text(choice.title)
                        }
                    }
                } label: {
                    // Filled while some rides are hidden, so a sighted driver can tell the list is filtered.
                    Label(
                        "Filter",
                        systemImage: filter == .all
                            ? "line.3.horizontal.decrease.circle"
                            : "line.3.horizontal.decrease.circle.fill"
                    )
                }
                .accessibilityValue(Text(filter.title))
            }
        }
        .onChange(of: filter) {
            announceFilter()
        }
    }

    private func showAllRides() {
        filter = .all
    }

    /// Tells VoiceOver users what the list shows now, as the rows change without moving their focus.
    private func announceFilter() {
        let count = (model.session?.pastRides ?? []).filter(filter.matches).count
        AccessibilityNotification.Announcement(String(localized: filter.announcement(showing: count))).post()
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
