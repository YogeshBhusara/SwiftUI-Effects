import Foundation
import Metal
import MetalKit
import simd
import UIKit

struct GradientGlassLinesParameters {
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
}

struct GradientGlassLinesUniformsSwift {
    var iResolution: vector_float3
    var iMouse: vector_float2
    var iTime: Float

    var uAngle: Float
    var uNoise: Float
    var uBlindCount: Float
    var uSpotlightRadius: Float
    var uSpotlightSoftness: Float
    var uSpotlightOpacity: Float
    var uMirror: Float
    var uDistort: Float
    var uShineFlip: Float

    var uColor0: vector_float3
    var uColor1: vector_float3
    var uColor2: vector_float3
    var uColor3: vector_float3
    var uColor4: vector_float3
    var uColor5: vector_float3
    var uColor6: vector_float3
    var uColor7: vector_float3
    var uColorCount: Int32
}

final class GradientGlassLinesRenderer: NSObject, MTKViewDelegate {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let pipelineState: MTLRenderPipelineState

    private var uniformsBuffer: MTLBuffer!
    private var params: GradientGlassLinesParameters

    private var viewportSize: vector_float2 = .zero
    private var startTime: CFTimeInterval = CACurrentMediaTime()

    private var currentMouse: vector_float2 = .zero
    private var targetMouse: vector_float2 = .zero
    private var lastFrameTime: CFTimeInterval = 0

    init(device: MTLDevice, view: MTKView, params: GradientGlassLinesParameters) {
        self.device = device
        self.commandQueue = device.makeCommandQueue()!
        self.params = params

        let library = device.makeDefaultLibrary()!
        let vertexFunc = library.makeFunction(name: "gradientGlassLinesVertex")!
        let fragmentFunc = library.makeFunction(name: "gradientGlassLinesFragment")!

        let pipelineDesc = MTLRenderPipelineDescriptor()
        pipelineDesc.vertexFunction = vertexFunc
        pipelineDesc.fragmentFunction = fragmentFunc
        pipelineDesc.colorAttachments[0].pixelFormat = view.colorPixelFormat
        self.pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineDesc)

        super.init()

        setupBuffers()
    }

    func updateParameters(_ newParams: GradientGlassLinesParameters) {
        params = newParams
    }

    private func setupBuffers() {
        uniformsBuffer = device.makeBuffer(length: MemoryLayout<GradientGlassLinesUniformsSwift>.stride,
                                           options: [.storageModeShared])
    }

    private func preparedColors() -> (colors: [vector_float3], count: Int32) {
        let maxColors = 8
        var uiColors = params.colors
        if uiColors.isEmpty {
            uiColors = [UIColor(red: 1, green: 0.623, blue: 0.988, alpha: 1),
                        UIColor(red: 0.322, green: 0.153, blue: 1, alpha: 1)]
        }
        if uiColors.count == 1 {
            uiColors.append(uiColors[0])
        }
        if uiColors.count > maxColors {
            uiColors = Array(uiColors.prefix(maxColors))
        }
        while uiColors.count < maxColors {
            if let last = uiColors.last {
                uiColors.append(last)
            } else {
                uiColors.append(.white)
            }
        }

        func uiColorToVec3(_ color: UIColor) -> vector_float3 {
            var r: CGFloat = 1
            var g: CGFloat = 1
            var b: CGFloat = 1
            var a: CGFloat = 1
            color.getRed(&r, green: &g, blue: &b, alpha: &a)
            return vector_float3(Float(r), Float(g), Float(b))
        }

        let vecs = uiColors.map { uiColorToVec3($0) }
        let count = Int32(max(2, min(maxColors, params.colors.count)))
        return (Array(vecs.prefix(maxColors)), count)
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        viewportSize = vector_float2(Float(size.width), Float(size.height))
    }

    func draw(in view: MTKView) {
        guard
            let drawable = view.currentDrawable,
            let descriptor = view.currentRenderPassDescriptor
        else { return }

        if viewportSize.x == 0 || viewportSize.y == 0 {
            let size = view.drawableSize
            viewportSize = vector_float2(Float(size.width), Float(size.height))
        }

        let now = CACurrentMediaTime()
        let time = Float(now - startTime)

        let dt: Float
        if lastFrameTime == 0 {
            dt = 0
        } else {
            dt = Float(now - lastFrameTime)
        }
        lastFrameTime = now

        let cx = viewportSize.x * 0.5
        let cy = viewportSize.y * 0.5
        let radius = min(viewportSize.x, viewportSize.y) * 0.25
        let autoTarget = vector_float2(
            cx + cosf(time * 0.4) * radius,
            cy + sinf(time * 0.7) * radius
        )
        targetMouse = autoTarget

        let damp = max(0.0, params.mouseDampening)
        if damp > 0, dt > 0 {
            let tau = max(1e-4, damp)
            var factor = 1 - exp(-dt / tau)
            if factor > 1 { factor = 1 }
            currentMouse += (targetMouse - currentMouse) * factor
        } else {
            currentMouse = targetMouse
        }

        let (colors, colorCount) = preparedColors()

        let blindMinWidth = max(1.0, params.blindMinWidth)
        let maxByMinWidth = max(1, Int(viewportSize.x / blindMinWidth))
        let effectiveBlindCount: Int
        if params.blindCount > 0 {
            effectiveBlindCount = min(params.blindCount, maxByMinWidth)
        } else {
            effectiveBlindCount = maxByMinWidth
        }

        var uniforms = GradientGlassLinesUniformsSwift(
            iResolution: vector_float3(viewportSize.x, viewportSize.y, 1),
            iMouse: currentMouse,
            iTime: time,
            uAngle: params.angle,
            uNoise: params.noise,
            uBlindCount: Float(max(1, effectiveBlindCount)),
            uSpotlightRadius: params.spotlightRadius,
            uSpotlightSoftness: params.spotlightSoftness,
            uSpotlightOpacity: params.spotlightOpacity,
            uMirror: params.mirrorGradient ? 1.0 : 0.0,
            uDistort: params.distortAmount,
            uShineFlip: params.shineDirectionIsRight ? 1.0 : 0.0,
            uColor0: colors[0],
            uColor1: colors[1],
            uColor2: colors[2],
            uColor3: colors[3],
            uColor4: colors[4],
            uColor5: colors[5],
            uColor6: colors[6],
            uColor7: colors[7],
            uColorCount: colorCount
        )

        memcpy(uniformsBuffer.contents(), &uniforms, MemoryLayout<GradientGlassLinesUniformsSwift>.stride)

        let commandBuffer = commandQueue.makeCommandBuffer()!
        let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)!
        encoder.setRenderPipelineState(pipelineState)

        encoder.setVertexBytes(&viewportSize,
                               length: MemoryLayout<vector_float2>.stride,
                               index: 0)

        encoder.setFragmentBuffer(uniformsBuffer, offset: 0, index: 0)

        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)

        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

