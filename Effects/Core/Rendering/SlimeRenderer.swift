import Foundation
import Metal
import MetalKit
import simd
import UIKit

struct SlimeParameters {
    var color: UIColor
    var cursorBallColor: UIColor
    var cursorBallSize: Float
    var ballCount: Int
    var animationSize: Float
    var clumpFactor: Float
    var speed: Float
    var enableTransparency: Bool
    var hoverSmoothness: Float
}

struct SlimeBallParam {
    var st: Float
    var dtFactor: Float
    var baseScale: Float
    var toggle: Float
    var radius: Float
}

struct SlimeUniforms {
    var iResolution: vector_float3
    var iTime: Float
    var iMouse: vector_float3
    var iColor: vector_float3
    var iCursorColor: vector_float3
    var iAnimationSize: Float
    var iBallCount: Int32
    var iCursorBallSize: Float
    var iClumpFactor: Float
    var enableTransparency: Int32
}

final class SlimeRenderer: NSObject, MTKViewDelegate {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let pipelineState: MTLRenderPipelineState

    private var startTime: CFTimeInterval = CACurrentMediaTime()

    private var uniformsBuffer: MTLBuffer!
    private var slimeBuffer: MTLBuffer!

    private var params: SlimeParameters
    private var ballParams: [SlimeBallParam] = []

    private var viewportSize: vector_float2 = .zero

    private var lastCursorPos: vector_float2 = .zero
    private var targetCursorPos: vector_float2 = .zero

    private static let maxBalls = 50

    init(device: MTLDevice, view: MTKView, params: SlimeParameters) {
        self.device = device
        self.commandQueue = device.makeCommandQueue()!
        self.params = params

        let library = device.makeDefaultLibrary()!
        let vertexFunc = library.makeFunction(name: "slimeVertex")!
        let fragmentFunc = library.makeFunction(name: "slimeFragment")!

        let pipelineDesc = MTLRenderPipelineDescriptor()
        pipelineDesc.vertexFunction = vertexFunc
        pipelineDesc.fragmentFunction = fragmentFunc
        pipelineDesc.colorAttachments[0].pixelFormat = view.colorPixelFormat
        self.pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineDesc)

        super.init()

        setupBuffers()
        generateBallParams()
    }

    func updateParameters(_ newParams: SlimeParameters) {
        let clampedBallCount = max(1, min(newParams.ballCount, SlimeRenderer.maxBalls))
        let previousBallCount = params.ballCount

        params = newParams
        params.ballCount = clampedBallCount

        if previousBallCount != clampedBallCount {
            generateBallParams()
        }
    }

    private func setupBuffers() {
        let uniformsSize = MemoryLayout<SlimeUniforms>.stride
        uniformsBuffer = device.makeBuffer(length: uniformsSize, options: [.storageModeShared])

        let metaBallSize = MemoryLayout<vector_float3>.stride * SlimeRenderer.maxBalls
        slimeBuffer = device.makeBuffer(length: metaBallSize, options: [.storageModeShared])
    }

    private func generateBallParams() {
        ballParams.removeAll()
        let effectiveCount = min(params.ballCount, SlimeRenderer.maxBalls)

        func fract(_ x: Float) -> Float {
            x - floorf(x)
        }

        func hash31(_ p: Float) -> SIMD3<Float> {
            var r = SIMD3<Float>(p * 0.1031, p * 0.103, p * 0.0973)
            r = SIMD3<Float>(fract(r.x), fract(r.y), fract(r.z))
            let ryzx = SIMD3<Float>(r.y, r.z, r.x)
            let dotVal = r.x * (ryzx.x + 33.33) + r.y * (ryzx.y + 33.33) + r.z * (ryzx.z + 33.33)
            r = SIMD3<Float>(
                fract(r.x + dotVal),
                fract(r.y + dotVal),
                fract(r.z + dotVal)
            )
            return r
        }

        func hash33(_ v: SIMD3<Float>) -> SIMD3<Float> {
            var p = SIMD3<Float>(
                v.x * 0.1031,
                v.y * 0.103,
                v.z * 0.0973
            )
            p = SIMD3<Float>(fract(p.x), fract(p.y), fract(p.z))
            let pyxz = SIMD3<Float>(p.y, p.x, p.z)
            let dotVal = p.x * (pyxz.x + 33.33) + p.y * (pyxz.y + 33.33) + p.z * (pyxz.z + 33.33)
            p = SIMD3<Float>(
                fract(p.x + dotVal),
                fract(p.y + dotVal),
                fract(p.z + dotVal)
            )
            let p_xxy = SIMD3<Float>(p.x, p.x, p.y)
            let p_yxx = SIMD3<Float>(p.y, p.x, p.x)
            let p_zyx = SIMD3<Float>(p.z, p.y, p.x)
            let result = SIMD3<Float>(
                fract((p_xxy.x + p_yxx.x) * p_zyx.x),
                fract((p_xxy.y + p_yxx.y) * p_zyx.y),
                fract((p_xxy.z + p_yxx.z) * p_zyx.z)
            )
            return result
        }

        for i in 0..<effectiveCount {
            let idx = Float(i + 1)
            let h1 = hash31(idx)
            let st = h1.x * (2 * Float.pi)
            // Varied speeds so blobs constantly merge and separate (liquid divide/merge)
            let dtFactor = 0.08 * Float.pi + h1.y * (0.5 * Float.pi - 0.08 * Float.pi)
            // Tighter orbit range so blobs interact more; varied radii for distinct blob sizes
            let baseScale = 4.0 + h1.y * (8.0 - 4.0)
            let h2 = hash33(h1)
            let toggle = floorf(h2.x * 2.0)
            // Mix of small and medium blobs for organic liquid look
            let radiusVal = 0.6 + h2.z * (1.8 - 0.6)

            ballParams.append(
                SlimeBallParam(
                    st: st,
                    dtFactor: dtFactor,
                    baseScale: baseScale,
                    toggle: toggle,
                    radius: radiusVal
                )
            )
        }
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

        let time = Float(CACurrentMediaTime() - startTime)

        let effectiveCount = min(params.ballCount, SlimeRenderer.maxBalls)
        let slimePointer = slimeBuffer.contents().bindMemory(to: vector_float3.self, capacity: SlimeRenderer.maxBalls)
        let slime = UnsafeMutableBufferPointer<vector_float3>(
            start: slimePointer,
            count: SlimeRenderer.maxBalls
        )
        slime.initialize(repeating: vector_float3(0, 0, 0))

        for i in 0..<effectiveCount {
            guard i < ballParams.count else { break }
            let p = ballParams[i]
            let dt = time * params.speed * p.dtFactor
            let th = p.st + dt
            let x = cosf(th)
            let y = sinf(th + dt * p.toggle)
            let posX = x * p.baseScale * params.clumpFactor
            let posY = y * p.baseScale * params.clumpFactor
            slime[i] = vector_float3(posX, posY, p.radius)
        }

        let cx = viewportSize.x * 0.5
        let cy = viewportSize.y * 0.5
        let rx = viewportSize.x * 0.15
        let ry = viewportSize.y * 0.15
        targetCursorPos = vector_float2(
            cx + cosf(time * params.speed) * rx,
            cy + sinf(time * params.speed) * ry
        )
        let smooth = params.hoverSmoothness
        lastCursorPos = lastCursorPos + (targetCursorPos - lastCursorPos) * smooth

        func uiColorToVec3(_ color: UIColor) -> vector_float3 {
            var r: CGFloat = 1
            var g: CGFloat = 1
            var b: CGFloat = 1
            var a: CGFloat = 1
            color.getRed(&r, green: &g, blue: &b, alpha: &a)
            return vector_float3(Float(r), Float(g), Float(b))
        }

        var uniforms = SlimeUniforms(
            iResolution: vector_float3(viewportSize.x, viewportSize.y, 0),
            iTime: time,
            iMouse: vector_float3(lastCursorPos.x, viewportSize.y - lastCursorPos.y, 0),
            iColor: uiColorToVec3(params.color),
            iCursorColor: uiColorToVec3(params.cursorBallColor),
            iAnimationSize: params.animationSize,
            iBallCount: Int32(effectiveCount),
            iCursorBallSize: params.cursorBallSize,
            iClumpFactor: params.clumpFactor,
            enableTransparency: params.enableTransparency ? 1 : 0
        )

        memcpy(uniformsBuffer.contents(), &uniforms, MemoryLayout<SlimeUniforms>.stride)

        let commandBuffer = commandQueue.makeCommandBuffer()!
        let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)!
        encoder.setRenderPipelineState(pipelineState)

        encoder.setVertexBytes(&viewportSize,
                               length: MemoryLayout<vector_float2>.stride,
                               index: 0)

        encoder.setFragmentBuffer(uniformsBuffer, offset: 0, index: 0)
        encoder.setFragmentBuffer(slimeBuffer, offset: 0, index: 1)

        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)

        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

