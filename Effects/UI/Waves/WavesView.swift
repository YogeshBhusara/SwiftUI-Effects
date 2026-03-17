import SwiftUI

private struct WavesConfig {
    var lineColor: Color
    var backgroundColor: Color
    var waveSpeedX: Double
    var waveSpeedY: Double
    var waveAmpX: Double
    var waveAmpY: Double
    var friction: Double
    var tension: Double
    var maxCursorMove: Double
    var xGap: Double
    var yGap: Double
}

private struct WavePoint {
    var baseX: Double
    var baseY: Double
    var waveX: Double = 0
    var waveY: Double = 0
    var cursorX: Double = 0
    var cursorY: Double = 0
    var vx: Double = 0
    var vy: Double = 0
}

private final class WavesEngine {
    var lines: [[WavePoint]] = []

    private(set) var config: WavesConfig
    private var lastTime: TimeInterval?
    private var canvasSize: CGSize = .zero

    private var mouseX: Double = -10
    private var mouseY: Double = 0
    private var smoothX: Double = 0
    private var smoothY: Double = 0
    private var lastLX: Double = 0
    private var lastLY: Double = 0
    private var velocityScalar: Double = 0
    private var velocitySmoothed: Double = 0
    private var angle: Double = 0

    init(config: WavesConfig) {
        self.config = config
    }

    func updateConfig(_ newConfig: WavesConfig) {
        config = newConfig
    }

    func updatePointer(at point: CGPoint?) {
        guard let point else { return }
        mouseX = point.x
        mouseY = point.y
        if lastTime == nil {
            smoothX = mouseX
            smoothY = mouseY
            lastLX = mouseX
            lastLY = mouseY
        }
    }

    func ensureGrid(size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }

        // Rebuild if first time or size changed materially
        if !lines.isEmpty, abs(size.width - canvasSize.width) < 0.5, abs(size.height - canvasSize.height) < 0.5 {
            return
        }
        canvasSize = size

        let width = Double(size.width)
        let height = Double(size.height)

        var newLines: [[WavePoint]] = []

        let oWidth = width + 200
        let oHeight = height + 30
        let totalLines = Int(ceil(oWidth / config.xGap))
        let totalPoints = Int(ceil(oHeight / config.yGap))
        let xStart = (width - config.xGap * Double(totalLines)) / 2
        let yStart = (height - config.yGap * Double(totalPoints)) / 2

        for i in 0...totalLines {
            var pts: [WavePoint] = []
            for j in 0...totalPoints {
                let x = xStart + config.xGap * Double(i)
                let y = yStart + config.yGap * Double(j)
                pts.append(WavePoint(baseX: x, baseY: y))
            }
            newLines.append(pts)
        }

        lines = newLines
    }

    func step(time: TimeInterval) {
        guard !lines.isEmpty else { return }

        if lastTime == nil {
            lastTime = time
            return
        }

        _ = time - (lastTime ?? time)
        lastTime = time

        // Mouse smoothing
        smoothX += (mouseX - smoothX) * 0.1
        smoothY += (mouseY - smoothY) * 0.1

        let dx = mouseX - lastLX
        let dy = mouseY - lastLY
        let d = hypot(dx, dy)
        velocityScalar = d
        velocitySmoothed += (d - velocitySmoothed) * 0.1
        velocitySmoothed = min(100, velocitySmoothed)
        lastLX = mouseX
        lastLY = mouseY
        angle = atan2(dy, dx)

        let waveSpeedX = config.waveSpeedX
        let waveSpeedY = config.waveSpeedY
        let waveAmpX = config.waveAmpX
        let waveAmpY = config.waveAmpY
        let friction = config.friction
        let tension = config.tension
        let maxCursorMove = config.maxCursorMove

        let w = Double(max(1, canvasSize.width))
        let h = Double(max(1, canvasSize.height))

        // Two animated "blob" centers create the big sweeping bulges seen in the reference.
        // These are purely for displacement; the visible result is warped vertical lines.
        let blob1 = SIMD3<Double>(
            w * (0.30 + 0.14 * cos(time * 0.18)),
            h * (0.52 + 0.18 * sin(time * 0.15)),
            min(w, h) * 0.42
        )
        let blob2 = SIMD3<Double>(
            w * (0.70 + 0.12 * sin(time * 0.21)),
            h * (0.48 + 0.16 * cos(time * 0.17)),
            min(w, h) * 0.38
        )

        @inline(__always)
        func blobDisplacement(px: Double, py: Double) -> SIMD2<Double> {
            var d = SIMD2<Double>(repeating: 0)
            let blobs = [blob1, blob2]
            for b in blobs {
                let vx = px - b.x
                let vy = py - b.y
                let dist2 = vx * vx + vy * vy
                let sigma2 = b.z * b.z
                let influence = exp(-dist2 / (2.0 * sigma2))
                let invLen = 1.0 / max(1.0, sqrt(dist2))
                // Stronger in X than Y to keep lines mostly vertical
                d.x += vx * invLen * influence
                d.y += vy * invLen * influence * 0.12
            }
            // Map to pixel-ish displacement; scaled by wave amplitudes.
            let strengthX = waveAmpX * 2.2
            let strengthY = waveAmpY * 0.25
            return SIMD2<Double>(d.x * strengthX, d.y * strengthY)
        }

        // Lightweight "flow" signal (not full Perlin) to keep continuous motion.
        @inline(__always)
        func flow(px: Double, py: Double) -> Double {
            let a = sin(py * 0.010 + time * (waveSpeedY * 70.0) + px * 0.0015)
            let b = cos(px * 0.006 + time * (waveSpeedX * 80.0) + py * 0.0012)
            return (a + b) * 0.5
        }

        for lineIdx in lines.indices {
            for ptIdx in lines[lineIdx].indices {
                var p = lines[lineIdx][ptIdx]

                let baseX = p.baseX
                let baseY = p.baseY

                let blob = blobDisplacement(px: baseX, py: baseY)
                let f = flow(px: baseX, py: baseY)
                // Mostly horizontal displacement; a tiny vertical component for organic drift.
                p.waveX = f * (waveAmpX * 0.65) + blob.x
                p.waveY = cos(baseX * 0.004 + time * (waveSpeedX * 60.0)) * (waveAmpY * 0.08) + blob.y

                let dxm = p.baseX - smoothX
                let dym = p.baseY - smoothY
                let dist = hypot(dxm, dym)
                let l = max(175, velocitySmoothed)
                if dist < l {
                    let s = 1 - dist / l
                    let f = cos(dist * 0.001) * s
                    let force = f * l * velocitySmoothed * 0.00065
                    p.vx += cos(angle) * force
                    p.vy += sin(angle) * force
                }

                p.vx += (0 - p.cursorX) * tension
                p.vy += (0 - p.cursorY) * tension
                p.vx *= friction
                p.vy *= friction
                p.cursorX += p.vx * 2.0
                p.cursorY += p.vy * 2.0
                p.cursorX = min(maxCursorMove, max(-maxCursorMove, p.cursorX))
                p.cursorY = min(maxCursorMove, max(-maxCursorMove, p.cursorY))

                lines[lineIdx][ptIdx] = p
            }
        }
    }

    func screenPosition(for point: WavePoint, includeCursor: Bool) -> CGPoint {
        let x = point.baseX + point.waveX + (includeCursor ? point.cursorX : 0)
        let y = point.baseY + point.waveY + (includeCursor ? point.cursorY : 0)
        return CGPoint(x: x, y: y)
    }
}

struct WavesView: View {
    var lineColor: Color
    var backgroundColor: Color
    var waveSpeedX: Double
    var waveSpeedY: Double
    var waveAmpX: Double
    var waveAmpY: Double
    var friction: Double
    var tension: Double
    var maxCursorMove: Double
    var xGap: Double
    var yGap: Double

    @State private var engine: WavesEngine

    init(
        lineColor: Color,
        backgroundColor: Color,
        waveSpeedX: Double,
        waveSpeedY: Double,
        waveAmpX: Double,
        waveAmpY: Double,
        friction: Double,
        tension: Double,
        maxCursorMove: Double,
        xGap: Double,
        yGap: Double
    ) {
        self.lineColor = lineColor
        self.backgroundColor = backgroundColor
        self.waveSpeedX = waveSpeedX
        self.waveSpeedY = waveSpeedY
        self.waveAmpX = waveAmpX
        self.waveAmpY = waveAmpY
        self.friction = friction
        self.tension = tension
        self.maxCursorMove = maxCursorMove
        self.xGap = xGap
        self.yGap = yGap

        let config = WavesConfig(
            lineColor: lineColor,
            backgroundColor: backgroundColor,
            waveSpeedX: waveSpeedX,
            waveSpeedY: waveSpeedY,
            waveAmpX: waveAmpX,
            waveAmpY: waveAmpY,
            friction: friction,
            tension: tension,
            maxCursorMove: maxCursorMove,
            xGap: xGap,
            yGap: yGap
        )
        _engine = State(initialValue: WavesEngine(config: config))
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            WavesCanvasView(
                engine: engine,
                config: WavesConfig(
                    lineColor: lineColor,
                    backgroundColor: backgroundColor,
                    waveSpeedX: waveSpeedX,
                    waveSpeedY: waveSpeedY,
                    waveAmpX: waveAmpX,
                    waveAmpY: waveAmpY,
                    friction: friction,
                    tension: tension,
                    maxCursorMove: maxCursorMove,
                    xGap: xGap,
                    yGap: yGap
                ),
                time: timeline.date.timeIntervalSinceReferenceDate
            )
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    engine.updatePointer(at: value.location)
                }
        )
    }
}

private struct WavesCanvasView: View {
    let engine: WavesEngine
    let config: WavesConfig
    let time: TimeInterval

    var body: some View {
        Canvas { context, size in
            engine.updateConfig(config)
            engine.ensureGrid(size: size)
            engine.step(time: time)

            // Dark, slightly purple background like the reference.
            let rect = CGRect(origin: .zero, size: size)
            let bg0 = Color(red: 0.03, green: 0.02, blue: 0.06)
            let bg1 = Color(red: 0.01, green: 0.01, blue: 0.03)
            context.fill(
                Path(rect),
                with: .linearGradient(
                    .init(colors: [bg0, bg1]),
                    startPoint: CGPoint(x: 0, y: 0),
                    endPoint: CGPoint(x: size.width, y: size.height)
                )
            )
            context.fill(Path(rect), with: .color(config.backgroundColor))

            guard !engine.lines.isEmpty else { return }

            var path = Path()

            for line in engine.lines {
                guard line.count >= 2 else { continue }
                path.move(to: engine.screenPosition(for: line[0], includeCursor: true))
                for idx in 1..<line.count {
                    path.addLine(to: engine.screenPosition(for: line[idx], includeCursor: true))
                }
            }

            let style = StrokeStyle(lineWidth: 1.0, lineCap: .round, lineJoin: .round)
            context.stroke(path, with: .color(config.lineColor.opacity(0.88)), style: style)
        }
    }
}

