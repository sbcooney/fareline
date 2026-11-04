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
                        // While a filter is on, the count shows how much of the history is showing. VoiceOver users
                        // also hear it when the filter changes.
                        if filter != .all {
                            Text(PastRideFilter.countDescription(showing: shownRides.count, of: rides.count))
                                // Section headers can default to capitals, and this reads as a sentence.
                                .textCase(nil)
                                // The system's header gray falls short of contrast in light mode, and the token is
                                // checked in both.
                                .foregroundStyle(.textSecondary)
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
                    // Filled while a filter other than All Rides is on, so a sighted driver can tell the list is
                    // filtered.
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
        var announcement = AttributedString(localized: filter.announcement(showing: count))
        // The menu closes and focus moves as the filter changes, which could otherwise cut this off.
        announcement.accessibilitySpeechAnnouncementPriority = .high
        AccessibilityNotification.Announcement(announcement).post()
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
