import SwiftUI

private struct RGB {
    var r: Double
    var g: Double
    var b: Double

    func lerp(to other: RGB, t: Double) -> RGB {
        RGB(
            r: r + (other.r - r) * t,
            g: g + (other.g - g) * t,
            b: b + (other.b - b) * t
        )
    }

    var color: Color {
        Color(red: r, green: g, blue: b)
    }
}

private struct GlitchCell {
    var char: Character
    var color: RGB
    var startColor: RGB
    var targetColor: RGB
    var progress: Double
}

private final class LetterGlitchEngine {
    private let characters: [Character]
    private let palette: [RGB]

    private(set) var columns: Int = 0
    private(set) var rows: Int = 0
    private(set) var cells: [GlitchCell] = []

    private var lastGlitchTime: TimeInterval = 0
    private var lastFrameTime: TimeInterval = 0

    private let fontSize: CGFloat = 16
    private let charWidth: CGFloat = 10
    private let charHeight: CGFloat = 20

    init(
        characters: String,
        palette: [RGB]
    ) {
        self.characters = Array(characters)
        self.palette = palette
    }

    func ensureGrid(size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }

        let newColumns = max(1, Int(ceil(size.width / charWidth)))
        let newRows = max(1, Int(ceil(size.height / charHeight)))
        if newColumns == columns, newRows == rows, !cells.isEmpty { return }

        columns = newColumns
        rows = newRows
        let total = columns * rows
        cells = (0..<total).map { _ in
            let c = randomChar()
            let col = randomColor()
            let tgt = randomColor()
            return GlitchCell(char: c, color: col, startColor: col, targetColor: tgt, progress: 1)
        }
    }

    func step(time: TimeInterval, glitchSpeedMs: Int, smooth: Bool) {
        guard !cells.isEmpty else { return }

        if lastFrameTime == 0 {
            lastFrameTime = time
            lastGlitchTime = time
            return
        }

        let dt = max(0, min(1.0 / 20.0, time - lastFrameTime))
        lastFrameTime = time

        let glitchInterval = Double(max(1, glitchSpeedMs)) / 1000.0
        if time - lastGlitchTime >= glitchInterval {
            updateRandomCells(smooth: smooth)
            lastGlitchTime = time
        }

        if smooth {
            // Similar to JS: progress += 0.05 per frame; here we scale by dt for consistent speed.
            let step = dt * 3.0
            for idx in cells.indices {
                var cell = cells[idx]
                guard cell.progress < 1 else { continue }
                cell.progress = min(1, cell.progress + step)
                cell.color = cell.startColor.lerp(to: cell.targetColor, t: cell.progress)
                cells[idx] = cell
            }
        } else {
            // No-op: immediate color updates happen in updateRandomCells
        }
    }

    func draw(into context: inout GraphicsContext, size: CGSize) {
        guard columns > 0, rows > 0 else { return }

        let font = Font.system(size: fontSize, weight: .regular, design: .monospaced)

        for idx in cells.indices {
            let x = CGFloat(idx % columns) * charWidth
            let y = CGFloat(idx / columns) * charHeight
            if y > size.height { break }

            let cell = cells[idx]
            context.draw(
                Text(String(cell.char))
                    .font(font)
                    .foregroundStyle(cell.color.color),
                at: CGPoint(x: x, y: y),
                anchor: .topLeading
            )
        }
    }

    private func updateRandomCells(smooth: Bool) {
        let updateCount = max(1, Int(Double(cells.count) * 0.05))
        for _ in 0..<updateCount {
            let idx = Int.random(in: 0..<cells.count)
            var cell = cells[idx]
            cell.char = randomChar()
            let next = randomColor()
            if smooth {
                cell.startColor = cell.color
                cell.targetColor = next
                cell.progress = 0
            } else {
                cell.color = next
                cell.startColor = next
                cell.targetColor = next
                cell.progress = 1
            }
            cells[idx] = cell
        }
    }

    private func randomChar() -> Character {
        characters[Int.random(in: 0..<characters.count)]
    }

    private func randomColor() -> RGB {
        palette[Int.random(in: 0..<palette.count)]
    }
}

struct LetterGlitchView: View {
    var glitchSpeedMs: Int
    var centerVignette: Bool
    var outerVignette: Bool
    var smooth: Bool

    @State private var engine = LetterGlitchEngine(
        characters: "ABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$&*()-_+=/[]{};:<>.,0123456789",
        palette: [
            RGB(r: 0x2b / 255.0, g: 0x45 / 255.0, b: 0x39 / 255.0),
            RGB(r: 0x61 / 255.0, g: 0xdc / 255.0, b: 0xa3 / 255.0),
            RGB(r: 0x61 / 255.0, g: 0xb3 / 255.0, b: 0xdc / 255.0)
        ]
    )

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                // Base background
                context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.black))

                engine.ensureGrid(size: size)
                engine.step(
                    time: timeline.date.timeIntervalSinceReferenceDate,
                    glitchSpeedMs: glitchSpeedMs,
                    smooth: smooth
                )

                engine.draw(into: &context, size: size)

                if outerVignette {
                    drawOuterVignette(into: &context, size: size)
                }
                if centerVignette {
                    drawCenterVignette(into: &context, size: size)
                }
            }
        }
    }

    private func drawOuterVignette(into context: inout GraphicsContext, size: CGSize) {
        let rect = CGRect(origin: .zero, size: size)
        let gradient = Gradient(stops: [
            .init(color: .black.opacity(0.0), location: 0.0),
            .init(color: .black.opacity(0.0), location: 0.6),
            .init(color: .black.opacity(1.0), location: 1.0)
        ])
        let shading = GraphicsContext.Shading.radialGradient(
            gradient,
            center: CGPoint(x: rect.midX, y: rect.midY),
            startRadius: 0,
            endRadius: max(rect.width, rect.height) * 0.65
        )
        context.fill(Path(rect), with: shading)
    }

    private func drawCenterVignette(into context: inout GraphicsContext, size: CGSize) {
        let rect = CGRect(origin: .zero, size: size)
        let gradient = Gradient(stops: [
            .init(color: .black.opacity(0.8), location: 0.0),
            .init(color: .black.opacity(0.0), location: 0.6)
        ])
        let shading = GraphicsContext.Shading.radialGradient(
            gradient,
            center: CGPoint(x: rect.midX, y: rect.midY),
            startRadius: 0,
            endRadius: max(rect.width, rect.height) * 0.55
        )
        context.fill(Path(rect), with: shading)
    }
}

