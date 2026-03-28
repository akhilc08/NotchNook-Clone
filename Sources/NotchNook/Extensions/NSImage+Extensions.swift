import AppKit
import SwiftUI

extension NSImage {
    /// Samples the image and returns the most vibrant color suitable for tinting
    /// dark UI on pure black. Picks the highest-saturation pixel rather than
    /// averaging, then normalises brightness into the 0.65–0.80 band so it
    /// always reads clearly against black.
    func dominantColor() -> Color {
        let fallback = Color(red: 0.30, green: 0.45, blue: 0.82)
        guard let cgImg = cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return fallback
        }
        let side = 32
        let bpr  = side * 4
        var pixels = [UInt8](repeating: 0, count: side * bpr)
        guard let ctx = CGContext(
            data: &pixels,
            width: side, height: side,
            bitsPerComponent: 8,
            bytesPerRow: bpr,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return fallback }

        ctx.draw(cgImg, in: CGRect(x: 0, y: 0, width: side, height: side))

        var bestScore: Double = -1
        var bestR: Double = 0, bestG: Double = 0, bestB: Double = 0

        for i in Swift.stride(from: 0, to: pixels.count, by: 4) {
            let r = Double(pixels[i])   / 255.0
            let g = Double(pixels[i+1]) / 255.0
            let b = Double(pixels[i+2]) / 255.0

            let maxC = max(r, g, b)
            let minC = min(r, g, b)
            let brightness  = maxC
            let saturation  = maxC > 0.001 ? (maxC - minC) / maxC : 0

            // Skip near-black and near-white — they make bad tint colors
            guard brightness > 0.12 && brightness < 0.93 else { continue }

            // Reward saturation; ideal brightness around 0.65, penalise extremes
            let brightPenalty = 1.0 - pow((brightness - 0.65) * 2.0, 2)
            let score = saturation * max(0, brightPenalty)

            if score > bestScore {
                bestScore = score
                bestR = r; bestG = g; bestB = b
            }
        }

        guard bestScore > 0.08 else { return fallback }

        // Normalise brightness into 0.65–0.80 so it reads well on pure black
        let maxC = max(bestR, bestG, bestB)
        if maxC > 0.001 {
            let targetBrightness = min(0.80, max(0.65, maxC))
            let scale = targetBrightness / maxC
            return Color(red: bestR * scale, green: bestG * scale, blue: bestB * scale)
        }
        return Color(red: bestR, green: bestG, blue: bestB)
    }
}
