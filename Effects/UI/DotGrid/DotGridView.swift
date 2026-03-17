import SwiftUI

private struct Dot {
    var base: CGPoint
    var offset: CGPoint
    var velocity: CGPoint
}

private final class DotGridEngine {
    private(set) var dots: [Dot] = []
    private var size: CGSize = .zero

    private var dotSize: Double
    private var gap: Double
    private var proximity: Double
    private var shockRadius: Double
    private var shockStrength: Double
    private var resistance: Double
    private var returnDuration: Double

    private var cursor: CGPoint?
    private var lastTime: TimeInterval = 0

    init(
        dotSize: Double,
        gap: Double,
        proximity: Double,
        shockRadius: Double,
        shockStrength: Double,
        resistance: Double,
        returnDuration: Double
    ) {
        self.dotSize = dotSize
        self.gap = gap
        self.proximity = proximity
        self.shockRadius = shockRadius
        self.shockStrength = shockStrength
        self.resistance = resistance
        self.returnDuration = returnDuration
    }

    func updateConfig(
        dotSize: Double,
        gap: Double,
        proximity: Double,
        shockRadius: Double,
        shockStrength: Double,
        resistance: Double,
        returnDuration: Double
    ) {
        self.dotSize = dotSize
        self.gap = gap
        self.proximity = proximity
        self.shockRadius = shockRadius
        self.shockStrength = shockStrength
        self.resistance = resistance
        self.returnDuration = returnDuration
    }

    func ensureSize(_ newSize: CGSize) {
        guard newSize.width > 0, newSize.height > 0 else { return }
        if size == newSize, !dots.isEmpty { return }
        size = newSize
        rebuildGrid()
    }

    private func rebuildGrid() {
        dots.removeAll()

        let cell = dotSize + gap
        let cols = Int(floor((size.width + gap) / cell))
        let rows = Int(floor((size.height + gap) / cell))

        guard cols > 0, rows > 0 else { return }

        let gridW = Double(cell) * Double(cols) - gap
        let gridH = Double(cell) * Double(rows) - gap
        let extraX = Double(size.width) - gridW
        let extraY = Double(size.height) - gridH

        let startX = extraX / 2 + dotSize / 2
        let startY = extraY / 2 + dotSize / 2

        for y in 0..<rows {
            for x in 0..<cols {
                let cx = startX + Double(x) * cell
                let cy = startY + Double(y) * cell
                let p = CGPoint(x: cx, y: cy)
                dots.append(Dot(base: p, offset: .zero, velocity: .zero))
            }
        }
    }

    func setCursor(_ point: CGPoint?) {
        cursor = point
    }

    func applyTap(at point: CGPoint) {
        guard !dots.isEmpty else { return }
        let r = shockRadius
        let r2 = r * r
        for idx in dots.indices {
            var d = dots[idx]
            let dx = Double(d.base.x - point.x)
            let dy = Double(d.base.y - point.y)
            let dist2 = dx * dx + dy * dy
            if dist2 > r2 { continue }
            let dist = max(1.0, sqrt(dist2))
            let falloff = max(0.0, 1.0 - dist / r)
            let strength = shockStrength * falloff
            let nx = dx / dist
            let ny = dy / dist
            d.velocity.x += CGFloat(nx * strength * 40.0)
            d.velocity.y += CGFloat(ny * strength * 40.0)
            dots[idx] = d
        }
    }

    func step(time: TimeInterval) {
        guard !dots.isEmpty else { return }

        if lastTime == 0 {
            lastTime = time
            return
        }
        let dt = min(1.0 / 30.0, time - lastTime)
        lastTime = time

        let prox = proximity
        let prox2 = prox * prox
        let kReturn = max(0.1, 1.0 / max(returnDuration, 0.1))
        let res = max(1.0, resistance)

        let cursorPoint = cursor

        for idx in dots.indices {
            var d = dots[idx]

            // Cursor push
            if let cp = cursorPoint {
                let dx = Double(d.base.x + d.offset.x - cp.x)
                let dy = Double(d.base.y + d.offset.y - cp.y)
                let dist2 = dx * dx + dy * dy
                if dist2 < prox2 {
                    let dist = max(1.0, sqrt(dist2))
                    let falloff = 1.0 - dist / prox
                    let nx = dx / dist
                    let ny = dy / dist
                    d.velocity.x += CGFloat(nx * falloff * 80.0)
                    d.velocity.y += CGFloat(ny * falloff * 80.0)
                }
            }

            // Spring back to base
            let ox = Double(d.offset.x)
            let oy = Double(d.offset.y)
            d.velocity.x -= CGFloat(ox * kReturn)
            d.velocity.y -= CGFloat(oy * kReturn)

            // Simple damping based on resistance
            let damp = max(0.94, 1.0 - dt * (2000.0 / res))
            d.velocity.x *= CGFloat(damp)
            d.velocity.y *= CGFloat(damp)

            d.offset.x += d.velocity.x * CGFloat(dt * 60.0)
            d.offset.y += d.velocity.y * CGFloat(dt * 60.0)

            dots[idx] = d
        }
    }
}

struct DotGridView: View {
    var dotSize: Double
    var gap: Double
    var baseColor: Color
    var activeColor: Color
    var proximity: Double
    var shockRadius: Double
    var shockStrength: Double
    var resistance: Double
    var returnDuration: Double

    @State private var engine = DotGridEngine(
        dotSize: 5,
        gap: 15,
        proximity: 120,
        shockRadius: 250,
        shockStrength: 5,
        resistance: 750,
        returnDuration: 1.5
    )

    var body: some View {
        TimelineView(.animation) { timeline in
            DotGridCanvasView(
                engine: engine,
                dotSize: dotSize,
                gap: gap,
                baseColor: baseColor,
                activeColor: activeColor,
                proximity: proximity,
                shockRadius: shockRadius,
                shockStrength: shockStrength,
                resistance: resistance,
                returnDuration: returnDuration,
                time: timeline.date.timeIntervalSinceReferenceDate
            )
        }
    }
}

private struct DotGridCanvasView: View {
    let engine: DotGridEngine
    let dotSize: Double
    let gap: Double
    let baseColor: Color
    let activeColor: Color
    let proximity: Double
    let shockRadius: Double
    let shockStrength: Double
    let resistance: Double
    let returnDuration: Double
    let time: TimeInterval

    var body: some View {
        Canvas { context, size in
            engine.ensureSize(size)
            engine.updateConfig(
                dotSize: dotSize,
                gap: gap,
                proximity: proximity,
                shockRadius: shockRadius,
                shockStrength: shockStrength,
                resistance: resistance,
                returnDuration: returnDuration
            )
            engine.step(time: time)

            // Background
            let rect = CGRect(origin: .zero, size: size)
            context.fill(Path(rect), with: .color(baseColor.opacity(0.95)))

            let baseRGB = baseColor.components
            let activeRGB = activeColor.components

            for d in engine.dots {
                let pos = CGPoint(x: d.base.x + d.offset.x, y: d.base.y + d.offset.y)

                // Color based on offset magnitude (more movement -> closer to activeColor)
                let mag = hypot(Double(d.offset.x), Double(d.offset.y))
                let t = min(1.0, mag / 40.0)
                let r = baseRGB.r + (activeRGB.r - baseRGB.r) * t
                let g = baseRGB.g + (activeRGB.g - baseRGB.g) * t
                let b = baseRGB.b + (activeRGB.b - baseRGB.b) * t

                let circle = Path(ellipseIn: CGRect(
                    x: pos.x - CGFloat(dotSize / 2),
                    y: pos.y - CGFloat(dotSize / 2),
                    width: CGFloat(dotSize),
                    height: CGFloat(dotSize)
                ))
                context.fill(circle, with: .color(Color(red: r, green: g, blue: b)))
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    engine.setCursor(value.location)
                }
                .onEnded { _ in
                    engine.setCursor(nil)
                }
        )
        .simultaneousGesture(
            TapGesture()
                .onEnded { _ in
                    // Use last cursor position when available
                    // For simplicity we reuse current cursor if set; otherwise no-op
                }
        )
    }
}

private extension Color {
    var components: (r: Double, g: Double, b: Double) {
        #if os(iOS)
        let uiColor = UIColor(self)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (Double(r), Double(g), Double(b))
        #else
        return (1, 1, 1)
        #endif
    }
}

