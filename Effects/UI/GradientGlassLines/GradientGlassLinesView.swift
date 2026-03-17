import SwiftUI
import MetalKit

struct GradientGlassLinesView: UIViewRepresentable {
    var colors: [UIColor]
    var angle: Float
    var noise: Float
    var blindCount: Int
    var blindMinWidth: Float
    var mouseDampening: Float
    var mirrorGradient: Bool
    var spotlightRadius: Float
    var spotlightSoftness: Float
    var spotlightOpacity: Float
    var distortAmount: Float
    var shineDirectionIsRight: Bool

    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.isPaused = false
        mtkView.enableSetNeedsDisplay = false
        mtkView.framebufferOnly = false
        mtkView.preferredFramesPerSecond = 60
        mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)

        guard let device = mtkView.device else { return mtkView }

        let renderer = GradientGlassLinesRenderer(
            device: device,
            view: mtkView,
            params: GradientGlassLinesParameters(
                colors: colors,
                angle: angle,
                noise: noise,
                blindCount: blindCount,
                blindMinWidth: blindMinWidth,
                mouseDampening: mouseDampening,
                mirrorGradient: mirrorGradient,
                spotlightRadius: spotlightRadius,
                spotlightSoftness: spotlightSoftness,
                spotlightOpacity: spotlightOpacity,
                distortAmount: distortAmount,
                shineDirectionIsRight: shineDirectionIsRight
            )
        )
        context.coordinator.renderer = renderer
        mtkView.delegate = renderer

        return mtkView
    }

    func updateUIView(_ uiView: MTKView, context: Context) {
        if let renderer = context.coordinator.renderer {
            renderer.updateParameters(
                GradientGlassLinesParameters(
                    colors: colors,
                    angle: angle,
                    noise: noise,
                    blindCount: blindCount,
                    blindMinWidth: blindMinWidth,
                    mouseDampening: mouseDampening,
                    mirrorGradient: mirrorGradient,
                    spotlightRadius: spotlightRadius,
                    spotlightSoftness: spotlightSoftness,
                    spotlightOpacity: spotlightOpacity,
                    distortAmount: distortAmount,
                    shineDirectionIsRight: shineDirectionIsRight
                )
            )
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var renderer: GradientGlassLinesRenderer?
    }
}

