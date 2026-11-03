import Foundation

extension Ride {
    /// How long the rider has waited at the given time, in whole minutes, as the waiting list shows it.
    ///
    /// The units are words rather than abbreviations, so VoiceOver reads them as they're written.
    func waitDescription(at date: Date) -> LocalizedStringResource {
        let minutes = Int(date.timeIntervalSince(requestedAt) / 60)
        guard minutes >= 1 else {
            return "Waiting less than a minute"
        }
        let wait = Duration.seconds(minutes * 60).formatted(.units(allowed: [.hours, .minutes], width: .wide))
        return "Waiting \(wait)"
    }
}
