import SwiftUI

struct EffectDetailView: View {
    let effectType: EffectType

    var body: some View {
        Group {
            switch effectType {
            case .slime:
                SlimeEffectScreen()
            case .waves:
                WavesEffectScreen()
            case .letterGlitch:
                LetterGlitchEffectScreen()
            case .gravityBalloons:
                GravityBalloonsEffectScreen()
            case .dotGrid:
                DotGridEffectScreen()
            case .gradientGlassLines:
                GradientGlassLinesEffectScreen()
            }
        }
        .navigationTitle(effectType.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

