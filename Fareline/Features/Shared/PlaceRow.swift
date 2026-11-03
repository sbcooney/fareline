import SwiftUI

/// Shows one stop on a ride, such as its pickup or drop-off.
struct PlaceRow: View {
    let title: LocalizedStringResource
    let place: Place

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.textSecondary)
            Text(place.name)
                .font(.headline)
            Text(place.address)
                .foregroundStyle(.textSecondary)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    List {
        PlaceRow(title: "Pickup", place: Place(name: "Union Station", address: "50 Massachusetts Ave NE"))
    }
}
