// Renders the 🗄️ emoji onto a transparent 1024×1024 PNG.
// Usage: swift scripts/make-icon.swift <output.png>

import AppKit

let emoji = "🗄️"
let pixels = 1024
/// Share of the canvas the glyph's longest side fills.
let fill: CGFloat = 0.8
/// Alpha cutoff for finding the glyph's edges; ignores faint antialiasing specks from the emoji font.
let alphaCutoff: CGFloat = 0.5

guard CommandLine.arguments.count == 2 else {
    FileHandle.standardError.write("usage: make-icon.swift <output.png>\n".data(using: .utf8)!)
    exit(1)
}
let output = URL(fileURLWithPath: CommandLine.arguments[1])

/// An RGBA bitmap of an exact pixel size, independent of screen scale.
func makeBitmap(_ size: Int) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    rep.size = NSSize(width: size, height: size)
    return rep
}

func draw(into rep: NSBitmapImageRep, _ body: () -> Void) {
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    NSGraphicsContext.current?.imageInterpolation = .high
    body()
    NSGraphicsContext.restoreGraphicsState()
}

// 1. Render the emoji large, with plenty of room around it.
let scratchSize = pixels * 2
let scratch = makeBitmap(scratchSize)
draw(into: scratch) {
    let text = NSAttributedString(string: emoji, attributes: [.font: NSFont.systemFont(ofSize: CGFloat(pixels))])
    let size = text.size()
    text.draw(at: NSPoint(x: (CGFloat(scratchSize) - size.width) / 2, y: (CGFloat(scratchSize) - size.height) / 2))
}

// 2. Find the glyph's visible bounds (bitmap rows run top-down).
var minX = scratchSize, minY = scratchSize, maxX = -1, maxY = -1
for y in 0..<scratchSize {
    for x in 0..<scratchSize where (scratch.colorAt(x: x, y: y)?.alphaComponent ?? 0) > alphaCutoff {
        minX = min(minX, x); maxX = max(maxX, x)
        minY = min(minY, y); maxY = max(maxY, y)
    }
}
guard maxX >= minX, maxY >= minY else {
    FileHandle.standardError.write("emoji rendered nothing\n".data(using: .utf8)!)
    exit(1)
}
let glyphW = CGFloat(maxX - minX + 1)
let glyphH = CGFloat(maxY - minY + 1)
// Convert the top-down row range into a bottom-up drawing rect.
let source = NSRect(x: CGFloat(minX), y: CGFloat(scratchSize - 1 - maxY), width: glyphW, height: glyphH)

// 3. Draw just the glyph, scaled and centered, onto the final canvas.
let scale = CGFloat(pixels) * fill / max(glyphW, glyphH)
let destW = glyphW * scale, destH = glyphH * scale
let dest = NSRect(x: (CGFloat(pixels) - destW) / 2, y: (CGFloat(pixels) - destH) / 2, width: destW, height: destH)

let final = makeBitmap(pixels)
draw(into: final) {
    scratch.draw(in: dest, from: source, operation: .copy, fraction: 1, respectFlipped: false, hints: nil)
}

guard let png = final.representation(using: .png, properties: [:]) else { exit(1) }
try png.write(to: output)
