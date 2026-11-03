/// A party to a ride.
///
/// This names who did something, such as who cancelled, without taking either party's point of view, so a
/// rider app can read the same values.
enum RideRole: Sendable, Codable {
    case rider
    case driver
}
