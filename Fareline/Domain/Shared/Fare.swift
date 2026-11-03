import Foundation

/// The price of a ride.
struct Fare: Equatable, Sendable, Codable {
    /// The amount, stored as a `Decimal` because binary floating point can't represent all currency values exactly.
    let amount: Decimal

    /// The ISO 4217 currency code, such as "USD".
    let currencyCode: String
}
