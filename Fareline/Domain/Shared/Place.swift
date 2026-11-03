/// A named location, such as a pickup or drop-off point.
struct Place: Equatable, Sendable, Codable {
    /// A short name, such as "Union Station".
    let name: String

    /// The street address.
    let address: String
}
