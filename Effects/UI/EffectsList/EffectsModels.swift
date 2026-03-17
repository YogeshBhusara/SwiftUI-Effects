import SwiftUI

enum EffectType: String, CaseIterable, Identifiable, Hashable {
    case slime
    case waves
    case letterGlitch
    case gravityBalloons
    case dotGrid
    case gradientGlassLines

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .slime:
            return "Slime"
        case .waves:
            return "Waves"
        case .letterGlitch:
            return "Letter Glitch"
        case .gravityBalloons:
            return "Gravity Balloons"
        case .dotGrid:
            return "Dot Grid"
        case .gradientGlassLines:
            return "Gradient Glass Lines"
        }
    }

    var subtitle: String {
        switch self {
        case .slime:
            return "Blobby, merging slime"
        case .waves:
            return "Perlin-driven flowing lines"
        case .letterGlitch:
            return "Matrix-like character glitches"
        case .gravityBalloons:
            return "Floating, bouncy balloons"
        case .dotGrid:
            return "Interactive dot grid"
        case .gradientGlassLines:
            return "Shimmering gradient glass blinds"
        }
    }

    var accentColor: Color {
        switch self {
        case .slime:
            return .cyan
        case .waves:
            return .blue
        case .letterGlitch:
            return .green
        case .gravityBalloons:
            return .orange
        case .dotGrid:
            return .purple
        case .gradientGlassLines:
            return .pink
        }
    }

    var iconName: String {
        switch self {
        case .slime:
            return "circle.hexagongrid"
        case .waves:
            return "waveform.path"
        case .letterGlitch:
            return "textformat.abc"
        case .gravityBalloons:
            return "circle.grid.2x2"
        case .dotGrid:
            return "circle.grid.cross"
        case .gradientGlassLines:
            return "rectangle.portrait.on.rectangle.portrait"
        }
    }
}

struct EffectItem: Identifiable {
    let id = UUID()
    let type: EffectType
}

