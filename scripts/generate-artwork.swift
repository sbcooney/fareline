// Draws Fareline's app icon and launch mark from the design system's color tokens.
//
// Usage, from the repository root:
//   swift scripts/generate-artwork.swift            Writes the icons and launch mark into the asset catalog.
//   swift scripts/generate-artwork.swift preview DIR Writes the icon concepts side by side into DIR, for review.
//
// The colors come from the asset catalog's color sets, so a brand change is a token edit and a rerun.

import AppKit
import Foundation
import SwiftUI

let assets = URL(filePath: "Fareline/Resources/Assets.xcassets")

/// Reads one appearance of a color set from the asset catalog.
func token(_ name: String, dark: Bool = false) -> Color {
    let url = assets.appending(path: "\(name).colorset/Contents.json")
    guard let data = try? Data(contentsOf: url),
          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let colors = json["colors"] as? [[String: Any]] else {
        fatalError("Couldn't read the \(name) color set")
    }
    let entry = colors.first { ($0["appearances"] != nil) == dark } ?? colors[0]
    let components = (entry["color"] as? [String: Any])?["components"] as? [String: String] ?? [:]
    func value(_ key: String) -> Double {
        Double(UInt8(components[key, default: "0x00"].dropFirst(2), radix: 16) ?? 0) / 255
    }
    return Color(.sRGB, red: value("red"), green: value("green"), blue: value("blue"))
}

/// The route: a curve from the pickup point to the drop-off point.
struct Route: Shape {
    /// How far the curve bends. 0 is a straight line.
    var bend: Double

    func path(in rect: CGRect) -> Path {
        // The line leaves the pickup ring from its edge, so the ring stays open. The curve leaves horizontally,
        // so the edge is directly to the right of the ring's center.
        let start = CGPoint(x: rect.minX + rect.width * (0.26 + 0.09), y: rect.minY + rect.height * 0.72)
        let end = CGPoint(x: rect.minX + rect.width * 0.74, y: rect.minY + rect.height * 0.28)
        var path = Path()
        path.move(to: start)
        path.addCurve(
            to: end,
            control1: CGPoint(x: start.x + rect.width * max(0, bend - 0.09), y: start.y),
            control2: CGPoint(x: end.x - rect.width * bend, y: end.y)
        )
        return path
    }
}

/// The mark: an S-curve route, with an open circle at pickup and a filled one at drop-off.
struct Mark: View {
    let color: Color
    var bend = 0.42

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size.width
            ZStack {
                Route(bend: bend)
                    .stroke(color, style: StrokeStyle(lineWidth: size * 0.075, lineCap: .round))
                Circle()
                    .strokeBorder(color, lineWidth: size * 0.05)
                    .frame(width: size * 0.18, height: size * 0.18)
                    .position(x: size * 0.26, y: size * 0.72)
                Circle()
                    .fill(color)
                    .frame(width: size * 0.2, height: size * 0.2)
                    .position(x: size * 0.74, y: size * 0.28)
            }
        }
    }
}

/// The icon at 1024 points. iOS rounds the corners, so the artwork fills the square.
struct Icon: View {
    enum Style { case standard, dark, tinted }
    let style: Style
    var bend = 0.42

    var body: some View {
        ZStack {
            switch style {
            case .standard:
                LinearGradient(
                    colors: [token("brandPrimary"), token("brandBackground")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                Mark(color: .white, bend: bend)
            case .dark:
                // iOS dark icons sit on a dark background, with the mark in the brand color.
                Color.black
                Mark(color: token("brandPrimary", dark: true), bend: bend)
            case .tinted:
                // iOS tints this grayscale image, so the mark is white on black.
                Color.black
                Mark(color: .white, bend: bend)
            }
        }
        .frame(width: 1024, height: 1024)
    }
}

@MainActor
func writePNG(_ view: some View, to url: URL, size: CGSize) {
    let renderer = ImageRenderer(content: view.frame(width: size.width, height: size.height))
    renderer.scale = 1
    guard let image = renderer.cgImage else {
        fatalError("Couldn't render \(url.lastPathComponent)")
    }
    let bitmap = NSBitmapImageRep(cgImage: image)
    guard let data = bitmap.representation(using: .png, properties: [:]) else {
        fatalError("Couldn't encode \(url.lastPathComponent)")
    }
    do {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url)
    } catch {
        fatalError("Couldn't write \(url.path()): \(error)")
    }
    print("Wrote \(url.path())")
}

@MainActor
func writePreviews(to folder: URL) {
    let concepts: [(name: String, bend: Double)] = [("gentle-curve", 0.2), ("s-curve", 0.42), ("deep-s-curve", 0.6)]
    for concept in concepts {
        let sheet = HStack(spacing: 40) {
            Icon(style: .standard, bend: concept.bend)
            Icon(style: .dark, bend: concept.bend)
            Icon(style: .tinted, bend: concept.bend)
        }
        .padding(40)
        .background(Color.white)
        writePNG(sheet, to: folder.appending(path: "icon-\(concept.name).png"), size: CGSize(width: 3232, height: 1104))
    }
}

/// Writes the three icons, and the launch mark at 2x and 3x, into the asset catalog.
@MainActor
func writeArtwork() {
    let icons = assets.appending(path: "AppIcon.appiconset")
    writePNG(Icon(style: .standard), to: icons.appending(path: "AppIcon.png"), size: CGSize(width: 1024, height: 1024))
    writePNG(Icon(style: .dark), to: icons.appending(path: "AppIcon-Dark.png"), size: CGSize(width: 1024, height: 1024))
    writePNG(
        Icon(style: .tinted),
        to: icons.appending(path: "AppIcon-Tinted.png"),
        size: CGSize(width: 1024, height: 1024)
    )

    // The launch screen shows the mark in white on `brandBackground`, at 160 points.
    let launch = assets.appending(path: "LaunchMark.imageset")
    for scale in [2, 3] {
        let side = Double(160 * scale)
        writePNG(
            Mark(color: .white),
            to: launch.appending(path: "LaunchMark@\(scale)x.png"),
            size: CGSize(width: side, height: side)
        )
    }
}

MainActor.assumeIsolated {
    let arguments = CommandLine.arguments.dropFirst()
    if arguments.first == "preview", let folder = arguments.dropFirst().first {
        writePreviews(to: URL(filePath: folder))
    } else {
        writeArtwork()
    }
}
