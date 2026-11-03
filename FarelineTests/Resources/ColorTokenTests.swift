import SwiftUI
import Testing
@testable import Fareline

/// Checks the design system's colors in light and dark mode, so a token change that hurts readability fails
/// in under a second, rather than only in the slower UI audits.
struct ColorTokenTests {
    /// Something a token is drawn on: another token, or a fixed iOS system background.
    enum Background: CustomTestStringConvertible {
        case token(Color, name: String)
        /// A system background, which has fixed values: its light and dark sRGB hex values.
        case system(name: String, light: UInt32, dark: UInt32)

        func color(in scheme: ColorScheme) -> Color {
            switch self {
            case .token(let color, _):
                color
            case .system(_, let light, let dark):
                Color(hex: scheme == .light ? light : dark)
            }
        }

        var testDescription: String {
            switch self {
            case .token(_, let name), .system(let name, _, _):
                name
            }
        }
    }

    /// A foreground drawn on a background, and the WCAG ratio it must meet.
    struct Pair: CustomTestStringConvertible {
        let name: String
        let foreground: Color
        let background: Background
        /// 4.5 for body text, and 3 for large text and symbols.
        let minimumRatio: Double

        var testDescription: String {
            "\(name) on \(background.testDescription)"
        }
    }

    static let screen = Background.system(name: "screen", light: 0xFFFFFF, dark: 0x000000)
    static let groupedScreen = Background.system(name: "grouped screen", light: 0xF2F2F7, dark: 0x000000)
    static let listCell = Background.system(name: "list cell", light: 0xFFFFFF, dark: 0x1C1C1E)
    static let raised = Background.token(.surfaceRaised, name: "surfaceRaised")

    static let pairs: [Pair] = [
        // Tinted text, such as Decline and alert buttons, and the toolbar's symbols.
        Pair(name: "brandPrimary", foreground: .brandPrimary, background: screen, minimumRatio: 4.5),
        Pair(name: "brandPrimary", foreground: .brandPrimary, background: groupedScreen, minimumRatio: 4.5),
        Pair(name: "brandPrimary", foreground: .brandPrimary, background: listCell, minimumRatio: 4.5),
        Pair(name: "brandPrimary", foreground: .brandPrimary, background: raised, minimumRatio: 4.5),
        // Labels on filled buttons, such as Accept.
        Pair(
            name: "textOnBrand",
            foreground: .textOnBrand,
            background: .token(.brandPrimary, name: "brandPrimary"),
            minimumRatio: 4.5
        ),
        // Supporting text in lists, on the home screen, and in the pending offer bar.
        Pair(name: "textSecondary", foreground: .textSecondary, background: screen, minimumRatio: 4.5),
        Pair(name: "textSecondary", foreground: .textSecondary, background: groupedScreen, minimumRatio: 4.5),
        Pair(name: "textSecondary", foreground: .textSecondary, background: listCell, minimumRatio: 4.5),
        Pair(name: "textSecondary", foreground: .textSecondary, background: raised, minimumRatio: 4.5),
        // The home screen's status symbol, which is large and not text.
        Pair(name: "statusOffline", foreground: .statusOffline, background: screen, minimumRatio: 3),
        Pair(name: "statusAvailable", foreground: .statusAvailable, background: screen, minimumRatio: 3),
        Pair(name: "statusOnRide", foreground: .statusOnRide, background: screen, minimumRatio: 3)
    ]

    static let tokens: [(name: String, color: Color)] = [
        ("brandPrimary", .brandPrimary),
        ("brandBackground", .brandBackground),
        ("textOnBrand", .textOnBrand),
        ("textSecondary", .textSecondary),
        ("surfaceRaised", .surfaceRaised),
        ("statusOffline", .statusOffline),
        ("statusAvailable", .statusAvailable),
        ("statusOnRide", .statusOnRide)
    ]

    @Test(arguments: pairs, [ColorScheme.light, .dark])
    func pairMeetsItsContrastRatio(_ pair: Pair, scheme: ColorScheme) {
        let ratio = contrastRatio(pair.foreground, pair.background.color(in: scheme), in: scheme)

        #expect(ratio >= pair.minimumRatio, "\(pair.testDescription) in \(scheme) mode is \(ratio):1")
    }

    @Test(arguments: tokens.map(\.name))
    func tokenHasADarkValue(_ name: String) throws {
        let color = try #require(Self.tokens.first { $0.name == name }?.color)

        // A color set with no dark value would silently reuse its light one.
        #expect(resolve(color, in: .light) != resolve(color, in: .dark))
    }

    private func resolve(_ color: Color, in scheme: ColorScheme) -> Color.Resolved {
        var environment = EnvironmentValues()
        environment.colorScheme = scheme
        return color.resolve(in: environment)
    }

    /// The WCAG 2 contrast ratio, from 1 to 21.
    private func contrastRatio(_ first: Color, _ second: Color, in scheme: ColorScheme) -> Double {
        let luminances = [first, second].map { color in
            // `Color.Resolved` gives linear sRGB components, which is what relative luminance is defined on.
            let resolved = resolve(color, in: scheme)
            return 0.2126 * Double(resolved.linearRed)
                + 0.7152 * Double(resolved.linearGreen)
                + 0.0722 * Double(resolved.linearBlue)
        }
        let lighter = luminances.max() ?? 0
        let darker = luminances.min() ?? 0
        return (lighter + 0.05) / (darker + 0.05)
    }
}

private extension Color {
    /// A fixed sRGB color, for the system backgrounds the tests compare against.
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
