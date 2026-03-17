import SwiftUI
import MetalKit

struct SlimeView: UIViewRepresentable {
    var color: UIColor = .white
    var cursorBallColor: UIColor = .white
    var cursorBallSize: Float = 2.0
    var ballCount: Int = 15
    var animationSize: Float = 10.0
    var clumpFactor: Float = 0.7
    var speed: Float = 0.1
    var enableTransparency: Bool = true
    var hoverSmoothness: Float = 0.113

    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.isPaused = false
        mtkView.enableSetNeedsDisplay = false
        mtkView.framebufferOnly = false
        mtkView.preferredFramesPerSecond = 60
        mtkView.clearColor = MTLClearColor(
            red: 0,
            green: 0,
            blue: 0,
            alpha: enableTransparency ? 0 : 1
        )

        guard let device = mtkView.device else { return mtkView }

        let renderer = SlimeRenderer(
            device: device,
            view: mtkView,
            params: SlimeParameters(
                color: color,
                cursorBallColor: cursorBallColor,
                cursorBallSize: cursorBallSize,
                ballCount: ballCount,
                animationSize: animationSize,
                clumpFactor: clumpFactor,
                speed: speed,
                enableTransparency: enableTransparency,
                hoverSmoothness: hoverSmoothness
            )
        )
        context.coordinator.renderer = renderer
        mtkView.delegate = renderer

        return mtkView
    }

    func updateUIView(_ uiView: MTKView, context: Context) {
        if let renderer = context.coordinator.renderer {
            renderer.updateParameters(
                SlimeParameters(
                    color: color,
                    cursorBallColor: cursorBallColor,
                    cursorBallSize: cursorBallSize,
                    ballCount: ballCount,
                    animationSize: animationSize,
                    clumpFactor: clumpFactor,
                    speed: speed,
                    enableTransparency: enableTransparency,
                    hoverSmoothness: hoverSmoothness
                )
            )
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var renderer: SlimeRenderer?
    }
}

