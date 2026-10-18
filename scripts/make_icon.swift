import AppKit

let size = 1024
let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
)!
let context = NSGraphicsContext(bitmapImageRep: bitmap)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = context

let canvas = NSRect(x: 0, y: 0, width: size, height: size)
NSGradient(colors: [
    NSColor(calibratedRed: 0.37, green: 0.69, blue: 0.99, alpha: 1),
    NSColor(calibratedRed: 0.05, green: 0.33, blue: 0.82, alpha: 1)
])!.draw(in: canvas, angle: 135)

let glow = NSBezierPath(ovalIn: NSRect(x: 475, y: 490, width: 540, height: 540))
NSColor.white.withAlphaComponent(0.08).setFill()
glow.fill()

let steps: [(CGFloat, CGFloat, CGFloat)] = [
    (185, 240, 255), (355, 240, 370), (525, 240, 485)
]
for (index, step) in steps.enumerated() {
    let bar = NSBezierPath(roundedRect: NSRect(x: step.0, y: step.1, width: 135, height: step.2), xRadius: 40, yRadius: 40)
    NSColor.white.withAlphaComponent([0.68, 0.84, 1.0][index]).setFill()
    bar.fill()
}

let star = NSBezierPath()
let points: [NSPoint] = [
    .init(x: 780, y: 850), .init(x: 798, y: 798),
    .init(x: 850, y: 780), .init(x: 798, y: 762),
    .init(x: 780, y: 710), .init(x: 762, y: 762),
    .init(x: 710, y: 780), .init(x: 762, y: 798)
]
star.move(to: points[0])
points.dropFirst().forEach { star.line(to: $0) }
star.close()
NSColor.white.setFill()
star.fill()

NSGraphicsContext.restoreGraphicsState()
let output = CommandLine.arguments[1]
try bitmap.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: output))
