import SwiftUI

extension DriverAvailability {
    var title: LocalizedStringResource {
        switch self {
        case .offline:
            "You're Offline"
        case .available:
            "You're Available"
        case .onRide:
            "You're On a Ride"
        }
    }

    var explanation: LocalizedStringResource {
        switch self {
        case .offline:
            "Go online to start receiving ride offers."
        case .available:
            "New ride offers will appear here."
        case .onRide:
            "You can go offline after this ride ends."
        }
    }

    /// The symbol for this status. Each differs in shape as well as color, so color isn't the only signal.
    var symbolName: String {
        switch self {
        case .offline:
            "moon.zzz.fill"
        case .available:
            "checkmark.circle.fill"
        case .onRide:
            "car.fill"
        }
    }

    var tint: Color {
        switch self {
        case .offline:
            .secondary
        case .available:
            .green
        case .onRide:
            .blue
        }
    }

    /// The title of the button that changes this status.
    var actionTitle: LocalizedStringResource {
        self == .offline ? "Go Online" : "Go Offline"
    }
}
