/// A named location, such as a pickup or drop-off point.
struct Place: Hashable, Codable, Sendable {
    /// A short name, such as "Union Station".
    let name: String

    /// The street address.
    let address: String
}
