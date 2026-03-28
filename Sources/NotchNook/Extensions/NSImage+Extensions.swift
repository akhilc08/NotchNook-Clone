import AppKit
import SwiftUI

extension NSImage {
    /// Samples the image at low resolution and returns a vibrant dominant color,
    /// skipping near-black and near-white pixels.
    func dominantColor() -> Color {
        guard let cgImg = cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return .blue
        }
        let side = 24
        let bpr  = side * 4
        var pixels = [UInt8](repeating: 0, count: side * bpr)
        guard let ctx = CGContext(
            data: &pixels,
            width: side, height: side,
            bitsPerComponent: 8,
            bytesPerRow: bpr,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return .blue }

        ctx.draw(cgImg, in: CGRect(x: 0, y: 0, width: side, height: side))

        var rS = 0, gS = 0, bS = 0, n = 0
        let stride = 4
        for i in Swift.stride(from: 0, to: pixels.count, by: stride) {
            let r = Int(pixels[i]), g = Int(pixels[i+1]), b = Int(pixels[i+2])
            let brightness = (r + g + b) / 3
            guard brightness > 25 && brightness < 230 else { continue }
            rS += r; gS += g; bS += b; n += 1
        }
        guard n > 0 else { return .blue }

        // Boost saturation slightly
        let rf = Double(rS) / Double(n) / 255.0
        let gf = Double(gS) / Double(n) / 255.0
        let bf = Double(bS) / Double(n) / 255.0
        return Color(red: rf, green: gf, blue: bf)
    }
}
