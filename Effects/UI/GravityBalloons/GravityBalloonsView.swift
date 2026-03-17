import SwiftUI

private struct Balloon {
    var position: CGPoint
    var velocity: CGVector
    var radius: CGFloat
    var color: Color
}

private final class GravityBalloonsEngine {
    private(set) var balloons: [Balloon] = []
    private var size: CGSize = .zero

    private var gravity: Double
    private var friction: Double
    private var wallBounce: Double
    private var followCursor: Bool

    private var cursor: CGPoint?
    private var lastResetKey: Int = 0

    init(
        count: Int,
        gravity: Double,
        friction: Double,
        wallBounce: Double,
        followCursor: Bool
    ) {
        self.gravity = gravity
        self.friction = friction
        self.wallBounce = wallBounce
        self.followCursor = followCursor
        reset(count: count, in: .zero)
    }

    func updateConfig(
        count: Int,
        gravity: Double,
        friction: Double,
        wallBounce: Double,
        followCursor: Bool,
        resetKey: Int
    ) {
        self.gravity = gravity
        self.friction = friction
        self.wallBounce = wallBounce
        self.followCursor = followCursor

        if resetKey != lastResetKey, size != .zero {
            reset(count: count, in: size)
            lastResetKey = resetKey
            return
        }

        if count != balloons.count, size != .zero {
            reset(count: count, in: size)
        }
    }

    func setCursor(_ point: CGPoint?) {
        cursor = point
    }

    func ensureSize(_ newSize: CGSize, count: Int) {
        guard newSize.width > 0, newSize.height > 0 else { return }
        if size == .zero {
            size = newSize
            reset(count: count, in: newSize)
        } else {
            size = newSize
        }
    }

    private func reset(count: Int, in size: CGSize) {
        guard size.width > 0, size.height > 0 else {
            balloons = []
            return
        }

        var balls: [Balloon] = []
        balls.reserveCapacity(count)
        let minRadius: CGFloat = 6
        let maxRadius: CGFloat = 20

        let palette: [Color] = [
            Color(red: 0.99, green: 0.58, blue: 0.58),
            Color(red: 0.99, green: 0.80, blue: 0.48),
            Color(red: 0.58, green: 0.83, blue: 1.0),
            Color(red: 0.66, green: 0.80, blue: 0.99),
            Color(red: 0.80, green: 0.66, blue: 1.0)
        ]

        for _ in 0..<max(count, 0) {
            let r = CGFloat.random(in: minRadius...maxRadius)
            let x = CGFloat.random(in: r...(size.width - r))
            let y = CGFloat.random(in: r...(size.height - r))
            let color = palette.randomElement() ?? .white
            balls.append(
                Balloon(
                    position: CGPoint(x: x, y: y),
                    velocity: CGVector(dx: 0, dy: 0),
                    radius: r,
                    color: color
                )
            )
        }

        balloons = balls
    }

    func step(deltaTime dt: Double) {
        guard !balloons.isEmpty, size != .zero else { return }

        let g = gravity
        let fr = friction
        let wb = wallBounce

        for idx in balloons.indices {
            var b = balloons[idx]

            // Gravity (downwards)
            b.velocity.dy += CGFloat(g * dt * 120.0)

            // Optional cursor attraction / disturbance
            if followCursor, let c = cursor {
                let dx = c.x - b.position.x
                let dy = c.y - b.position.y
                let dist2 = dx * dx + dy * dy
                if dist2 > 0 {
                    let dist = sqrt(dist2)
                    let strength = min(1600.0 / max(dist2, 80.0), 1.5)
                    let nx = dx / max(dist, 1)
                    let ny = dy / max(dist, 1)
                    b.velocity.dx += nx * CGFloat(strength)
                    b.velocity.dy += ny * CGFloat(strength)
                }
            }

            // Integrate
            b.position.x += b.velocity.dx * CGFloat(dt * 60.0)
            b.position.y += b.velocity.dy * CGFloat(dt * 60.0)

            // Dampen
            b.velocity.dx *= CGFloat(fr)
            b.velocity.dy *= CGFloat(fr)

            // Walls
            let r = b.radius
            if b.position.x - r < 0 {
                b.position.x = r
                b.velocity.dx = -b.velocity.dx * CGFloat(wb)
            } else if b.position.x + r > size.width {
                b.position.x = size.width - r
                b.velocity.dx = -b.velocity.dx * CGFloat(wb)
            }

            if b.position.y - r < 0 {
                b.position.y = r
                b.velocity.dy = -b.velocity.dy * CGFloat(wb)
            } else if b.position.y + r > size.height {
                b.position.y = size.height - r
                b.velocity.dy = -b.velocity.dy * CGFloat(wb)
            }

            balloons[idx] = b
        }
    }
}

struct GravityBalloonsView: View {
    var count: Int
    var gravity: Double
    var friction: Double
    var wallBounce: Double
    var followCursor: Bool

    var resetKey: Int

    @State private var engine = GravityBalloonsEngine(
        count: 80,
        gravity: 0.08,
        friction: 0.995,
        wallBounce: 0.9,
        followCursor: false
    )

    var body: some View {
        TimelineView(.animation) { timeline in
            GeometryReader { geo in
                Canvas { context, size in
                    engine.ensureSize(size, count: count)
                    engine.updateConfig(
                        count: count,
                        gravity: gravity,
                        friction: friction,
                        wallBounce: wallBounce,
                        followCursor: followCursor,
                        resetKey: resetKey
                    )

                    let dt = min(1.0 / 30.0, timeline.date.timeIntervalSinceReferenceDate)
                    engine.step(deltaTime: dt)

                    // Background
                    let rect = CGRect(origin: .zero, size: size)
                    let bg = Gradient(stops: [
                        .init(color: Color(red: 0.04, green: 0.02, blue: 0.08), location: 0),
                        .init(color: Color(red: 0.01, green: 0.01, blue: 0.03), location: 1)
                    ])
                    context.fill(
                        Path(rect),
                        with: .linearGradient(
                            bg,
                            startPoint: CGPoint(x: 0, y: 0),
                            endPoint: CGPoint(x: size.width, y: size.height)
                        )
                    )

                    // Draw balloons
                    for b in engine.balloons {
                        let circle = Path(ellipseIn: CGRect(
                            x: b.position.x - b.radius,
                            y: b.position.y - b.radius,
                            width: b.radius * 2,
                            height: b.radius * 2
                        ))

                        context.fill(circle, with: .color(b.color))

                        // Simple specular highlight
                        let highlightRect = CGRect(
                            x: b.position.x - b.radius * 0.5,
                            y: b.position.y - b.radius * 0.8,
                            width: b.radius * 0.8,
                            height: b.radius * 0.8
                        )
                        let highlight = Path(ellipseIn: highlightRect)
                        context.fill(highlight, with: .color(.white.opacity(0.25)))
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
            }
        }
    }
}

