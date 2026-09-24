import UIKit

/// Color palettes drawn from specific Monet paintings, reused as the game's
/// entire art direction: soft layered brush dabs instead of flat shapes.
enum MonetPalette {
    // "Impression, Sunrise" — dawn sky over the harbor.
    static let skyGradient: [UIColor] = [
        UIColor(red: 0.62, green: 0.72, blue: 0.80, alpha: 1),
        UIColor(red: 0.80, green: 0.83, blue: 0.82, alpha: 1)
    ]
    static let skyDabs: [UIColor] = [
        UIColor(red: 0.55, green: 0.66, blue: 0.78, alpha: 1),
        UIColor(red: 0.72, green: 0.78, blue: 0.83, alpha: 1),
        UIColor(red: 0.78, green: 0.70, blue: 0.74, alpha: 1),
        UIColor(red: 0.90, green: 0.85, blue: 0.78, alpha: 1)
    ]
    static let sunGlow: [UIColor] = [
        UIColor(red: 0.95, green: 0.60, blue: 0.42, alpha: 1),
        UIColor(red: 0.97, green: 0.75, blue: 0.55, alpha: 1)
    ]

    // "Coquelicots" (Poppy Field) — meadow greens and gold with poppy accents.
    static let groundGradient: [UIColor] = [
        UIColor(red: 0.47, green: 0.58, blue: 0.32, alpha: 1),
        UIColor(red: 0.63, green: 0.68, blue: 0.36, alpha: 1)
    ]
    static let groundDabs: [UIColor] = [
        UIColor(red: 0.41, green: 0.53, blue: 0.28, alpha: 1),
        UIColor(red: 0.70, green: 0.72, blue: 0.38, alpha: 1),
        UIColor(red: 0.55, green: 0.62, blue: 0.30, alpha: 1),
        UIColor(red: 0.36, green: 0.45, blue: 0.24, alpha: 1)
    ]
    static let poppyAccents: [UIColor] = [
        UIColor(red: 0.76, green: 0.25, blue: 0.18, alpha: 1),
        UIColor(red: 0.86, green: 0.42, blue: 0.24, alpha: 1)
    ]

    // "Nymphéas" (Water Lilies) — deep pond greens with lily blossoms.
    static let pipeGradient: [UIColor] = [
        UIColor(red: 0.16, green: 0.32, blue: 0.27, alpha: 1),
        UIColor(red: 0.24, green: 0.44, blue: 0.36, alpha: 1)
    ]
    static let pipeDabs: [UIColor] = [
        UIColor(red: 0.20, green: 0.38, blue: 0.30, alpha: 1),
        UIColor(red: 0.30, green: 0.50, blue: 0.40, alpha: 1),
        UIColor(red: 0.14, green: 0.27, blue: 0.24, alpha: 1),
        UIColor(red: 0.35, green: 0.55, blue: 0.42, alpha: 1)
    ]
    static let lilyAccents: [UIColor] = [
        UIColor(red: 0.94, green: 0.85, blue: 0.88, alpha: 1),
        UIColor(red: 0.87, green: 0.62, blue: 0.71, alpha: 1)
    ]

    /// The single canonical gold used everywhere a "picture frame" accent
    /// appears — the bird's photo ring and the SwiftUI button/menu chrome
    /// (see `MonetTint.gold` in ContentView.swift, which derives from this).
    static let frameGold = UIColor(red: 0.72, green: 0.56, blue: 0.28, alpha: 1)
}

/// Paints soft, overlapping elliptical "brush dabs" over a gradient wash to
/// approximate an impressionist canvas — this is the game's entire visual
/// identity, generated in code rather than drawn from image assets.
enum MonetPainter {
    static func paint(size: CGSize,
                       gradientColors: [UIColor],
                       dabColors: [UIColor],
                       dabCount: Int,
                       dabSizeRange: ClosedRange<CGFloat>,
                       accentColors: [UIColor] = [],
                       accentCount: Int = 0,
                       accentSizeRange: ClosedRange<CGFloat> = 1...1) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let cg = ctx.cgContext
            drawVerticalGradient(cg, size: size, colors: gradientColors)

            for _ in 0..<dabCount {
                drawDab(cg, in: size, color: dabColors.randomElement()!,
                        sizeRange: dabSizeRange, opacityRange: 0.12...0.38)
            }
            for _ in 0..<accentCount {
                drawDab(cg, in: size, color: accentColors.randomElement()!,
                        sizeRange: accentSizeRange, opacityRange: 0.55...0.85)
            }
        }
    }

    private static func drawVerticalGradient(_ cg: CGContext, size: CGSize, colors: [UIColor]) {
        let space = CGColorSpaceCreateDeviceRGB()
        let cgColors = colors.map(\.cgColor) as CFArray
        guard let gradient = CGGradient(colorsSpace: space, colors: cgColors, locations: nil) else { return }
        cg.drawLinearGradient(gradient,
                               start: CGPoint(x: size.width / 2, y: 0),
                               end: CGPoint(x: size.width / 2, y: size.height),
                               options: [])
    }

    /// A full sky-over-meadow scene for the SwiftUI menu/game-over backdrops,
    /// built from the same palettes and dab technique as the in-game canvases
    /// so the whole app reads as one consistent painting.
    static func landscape(size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let cg = ctx.cgContext
            drawVerticalGradient(cg, size: size, colors: MonetPalette.skyGradient)

            for _ in 0..<150 {
                drawDab(cg, in: size, color: MonetPalette.skyDabs.randomElement()!,
                        sizeRange: 70...200, opacityRange: 0.10...0.30)
            }
            for _ in 0..<16 {
                drawDab(cg, in: size, color: MonetPalette.sunGlow.randomElement()!,
                        sizeRange: 60...140, opacityRange: 0.35...0.6)
            }

            let groundRect = CGRect(x: 0, y: size.height * 0.72, width: size.width, height: size.height * 0.28)
            cg.saveGState()
            cg.clip(to: groundRect)
            drawVerticalGradient(cg, size: size, colors: MonetPalette.groundGradient)
            for _ in 0..<110 {
                drawDab(cg, in: size, color: MonetPalette.groundDabs.randomElement()!,
                        sizeRange: 24...70, opacityRange: 0.15...0.4)
            }
            for _ in 0..<22 {
                drawDab(cg, in: size, color: MonetPalette.poppyAccents.randomElement()!,
                        sizeRange: 8...16, opacityRange: 0.55...0.85)
            }
            cg.restoreGState()
        }
    }

    private static func drawDab(_ cg: CGContext, in size: CGSize, color: UIColor,
                                 sizeRange: ClosedRange<CGFloat>, opacityRange: ClosedRange<CGFloat>) {
        let w = CGFloat.random(in: sizeRange)
        let h = w * CGFloat.random(in: 0.35...1.0)
        let x = CGFloat.random(in: -w...size.width)
        let y = CGFloat.random(in: -h...size.height)
        let angle = CGFloat.random(in: 0..<(.pi * 2))
        let alpha = CGFloat.random(in: opacityRange)

        cg.saveGState()
        cg.translateBy(x: x + w / 2, y: y + h / 2)
        cg.rotate(by: angle)
        cg.setFillColor(color.withAlphaComponent(alpha).cgColor)
        cg.fillEllipse(in: CGRect(x: -w / 2, y: -h / 2, width: w, height: h))
        cg.restoreGState()
    }
}
