// additive PlaGo node: app-injected view orientation (gyro + drag + fling compose)

import MetalKit
import ModelIO
import MuVision
import MuFlo

/// app-supplied view orientation; nil source falls back to device attitude
public protocol PlatoOrientationSource: AnyObject {
    @MainActor func viewOrientation() -> matrix_float4x4
}

/// one board viewport: scissored rect plus its own eye matrices
public struct PlaGoViewSpec: @unchecked Sendable {
    public let viewport: MTLViewport
    public let scissor: MTLScissorRect
    public let viewModel: matrix_float4x4
    public let projection: matrix_float4x4
    /// environment orientation for sky lookups; nil follows the view model
    public let envView: matrix_float4x4?

    public init(viewport: MTLViewport,
                scissor: MTLScissorRect,
                viewModel: matrix_float4x4,
                projection: matrix_float4x4,
                envView: matrix_float4x4? = nil) {
        self.viewport = viewport
        self.scissor = scissor
        self.viewModel = viewModel
        self.projection = projection
        self.envView = envView
    }
}

/// app-built mesh: non-indexed triangle list, replaces the mtkMesh draw
public struct PlaGoCustomMesh {
    public let buffer: MTLBuffer
    public let vertexCount: Int

    public init(buffer: MTLBuffer, vertexCount: Int) {
        self.buffer = buffer
        self.vertexCount = vertexCount
    }
}

/// view→world rotation for env sampling: columns of transpose(viewModel 3×3)
public struct SceneExtra {
    public var col0: SIMD4<Float>
    public var col1: SIMD4<Float>
    public var col2: SIMD4<Float>

    /// translation dropped; a rotation transpose is its inverse
    public init(_ viewModel: matrix_float4x4) {
        let c0 = viewModel.columns.0
        let c1 = viewModel.columns.1
        let c2 = viewModel.columns.2
        col0 = SIMD4<Float>(c0.x, c1.x, c2.x, 0)
        col1 = SIMD4<Float>(c0.y, c1.y, c2.y, 0)
        col2 = SIMD4<Float>(c0.z, c1.z, c2.z, 0)
    }
}

public class PlaGoPlatoNode: PlatoNode, @unchecked Sendable {

    nonisolated(unsafe) public static weak var orientationSource: PlatoOrientationSource?

    /// app-supplied viewports; set means multi-view glass render
    nonisolated(unsafe) public static var viewsProvider: (@MainActor () -> [PlaGoViewSpec])?

    /// per-space owner colors, sampled by faceId
    nonisolated(unsafe) public static var ownerTexture: MTLTexture?

    /// equirect star map: glass reflections and the sky backdrop
    nonisolated(unsafe) public static var envTexture: MTLTexture?

    /// app-supplied board mesh; nil falls back to the package mtkMesh
    nonisolated(unsafe) public static var customMesh: PlaGoCustomMesh?

    /// mesh morph position: dodec 0, icosa 1
    nonisolated(unsafe) public static var range01Value: Float = 0

    /// platonic glass on; classic pushes false for an opaque board
    nonisolated(unsafe) public static var glassOn = true

    /// sphere surface: fragment shading takes the radial normal
    nonisolated(unsafe) public static var sphereSmooth = false

    /// mirrors C `Eyes`: both slots hold the same eye
    private struct UniEyesPair {
        var eye0: UniformEye
        var eye1: UniformEye
    }
    /// facing split plus view-angle alpha ramp for the glass passes
    private struct GlassPass {
        var front: Float
        var alpha0: Float
        var alpha1: Float
        var dim: Float
    }
    private var backState: MTLDepthStencilState?
    private var frontState: MTLDepthStencilState?

    /// live model accessor for board-graph export
    public var exportModel: PlatoModel { platoMesh.model }

    override open func updateUniforms() {
        guard PlaGoPlatoNode.viewsProvider == nil else {
            // specs carry the eye uniforms; none written here
            return updatePlato()
        }
        guard PlaGoPlatoNode.orientationSource != nil else {
            return super.updateUniforms()
        }
        updatePlato()
        // render loop runs on the main actor; read synchronously so eye
        // uniforms never lag the frame that draws them
        MainActor.assumeIsolated {
            guard let source = PlaGoPlatoNode.orientationSource else { return }
            let orientation = source.viewOrientation()
            let cameraPos = vector_float4([0, 0, 4 * (platoFlo.zoom - 1), 1])
            let viewModel = translate4x4(cameraPos) * orientation
            platoMesh.eyeBuf?.updateMetalEyeUniforms(viewModel)
        }
    }

    override public func renderShader(_ encoder: MTLRenderCommandEncoder,
                                      _ state: RenderState) {
        guard PlaGoPlatoNode.viewsProvider != nil else {
            return super.renderShader(encoder, state)
        }
        guard let renderPipelineState else { return }
        makeGlassStates()
        guard let backState, let frontState else { return }

        let specs = MainActor.assumeIsolated { Self.viewsProvider?() ?? [] }
        var shading: PlatoShading = platoShading
        var range = Self.range01Value
        let glassOn = Self.glassOn
        var smooth: Float = Self.sphereSmooth ? 1 : 0

        for spec in specs {
            encoder.setViewport(spec.viewport)
            encoder.setScissorRect(spec.scissor)

            let eye = UniformEye(spec.projection, spec.viewModel)
            var eyes = UniEyesPair(eye0: eye, eye1: eye)
            // per-spec env orientation; bound once, read by both glass passes
            var scene = SceneExtra(spec.envView ?? spec.viewModel)
            encoder.setVertexBytes(&eyes, length: MemoryLayout<UniEyesPair>.stride, index: 15)
            encoder.setVertexBytes(&range, length: MemoryLayout<Float>.stride, index: 1)
            encoder.setFragmentBytes(&shading, length: MemoryLayout<PlatoShading>.stride, index: 1)
            encoder.setFragmentBytes(&scene, length: MemoryLayout<SceneExtra>.stride, index: 4)
            encoder.setFragmentBytes(&smooth, length: MemoryLayout<Float>.stride, index: 6)
            encoder.setFragmentTexture(Self.ownerTexture, index: 2)
            encoder.setFragmentTexture(Self.envTexture, index: 5)
            encoder.setRenderPipelineState(renderPipelineState)
            encoder.setCullMode(.none)
            encoder.setTriangleFillMode(.fill)

            // back hemisphere hint; opaque boards skip it
            if glassOn {
                var back = GlassPass(front: 0, alpha0: 0.22, alpha1: 0.22, dim: 0.40)
                encoder.setFragmentBytes(&back, length: MemoryLayout<GlassPass>.stride, index: 3)
                encoder.setDepthStencilState(backState)
                drawGlassMesh(encoder)
            }
            var front = glassOn
                ? GlassPass(front: 1, alpha0: 0.88, alpha1: 0.98, dim: 1)
                : GlassPass(front: 1, alpha0: 1, alpha1: 1, dim: 1)
            encoder.setFragmentBytes(&front, length: MemoryLayout<GlassPass>.stride, index: 3)
            encoder.setDepthStencilState(frontState)
            drawGlassMesh(encoder)
        }
        platoMesh.updateCounter()
    }

    /// both passes write depth: coincident coplanar tris (icosa fans) must
    /// blend exactly once per pixel, never stack
    private func makeGlassStates() {
        guard backState == nil else { return }
        let depth = MTLDepthStencilDescriptor()
        depth.depthCompareFunction = .less
        depth.isDepthWriteEnabled = true
        backState = pipeline.device.makeDepthStencilState(descriptor: depth)
        frontState = pipeline.device.makeDepthStencilState(descriptor: depth)
    }

    /// MeshMetal.drawMesh body without the depthRendering stencil override
    private func drawGlassMesh(_ encoder: MTLRenderCommandEncoder) {
        // app mesh wins: one non-indexed triangle list at vertex index 0
        if let customMesh = Self.customMesh {
            encoder.setVertexBuffer(customMesh.buffer, offset: 0, index: 0)
            encoder.drawPrimitives(type: .triangle,
                                   vertexStart: 0,
                                   vertexCount: customMesh.vertexCount)
            return
        }
        guard let mtkMesh = platoMesh.mtkMesh else { return }

        for (index, layout) in mtkMesh.vertexDescriptor.layouts.enumerated() {
            if let layout = layout as? MDLVertexBufferLayout,
               layout.stride != 0 {
                let vb = mtkMesh.vertexBuffers[index]
                encoder.setVertexBuffer(vb.buffer, offset: vb.offset, index: index)
            }
        }
        for submesh in mtkMesh.submeshes {
            encoder.drawIndexedPrimitives(
                type              : submesh.primitiveType,
                indexCount        : submesh.indexCount,
                indexType         : submesh.indexType,
                indexBuffer       : submesh.indexBuffer.buffer,
                indexBufferOffset : submesh.indexBuffer.offset)
        }
    }
}
