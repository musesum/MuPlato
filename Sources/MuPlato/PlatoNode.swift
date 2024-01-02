//  created by musesum on 3/16/23.

import MetalKit
import MuMetal
import MuVision
#if os(visionOS)
import CompositorServices
#endif

struct PlatoUniforms {
    var range        : Float
    var convex       : Float
    var passthru     : Float
    var shadowWhite  : Float
    var shadowDepth  : Float
    var invert       : Float
    var zoom         : Float
    var projectModel : matrix_float4x4
    var worldCamera  : vector_float4
    var identity     : matrix_float4x4
}

enum PlatoStyle: Int {

    case unknown = -1
    case hidden  = 0
    case color   = 1
    case reflect = 2

    public init(_ i: Int) {
        self = PlatoStyle(rawValue: i) ?? .hidden
    }
}


public class PlatoNode: RenderNode {

    var metal      : PlatoMetal!
    var uniforms   : PlatoUniforms?
    let platoFlo   = PlatoFlo.shared
    let cubeFlo    = CubeFlo.shared
    var platoStyle = PlatoStyle.reflect

    public var getPal: GetTextureFunc?

    public init(_ pipeline: Pipeline,
                _ getPal: @escaping GetTextureFunc) {
        
        super.init(pipeline, "plato", "render.plato", .rendering)
        self.metal = PlatoMetal(pipeline.device)
        self.filename = filename
        self.getPal = getPal

        makeLibrary()
        makeResources()
        makePipeline()
    }

    func makeResources() {

        metal.eyeBuf = UniformEyeBuf(metal.device, "Plato", far: false)
        metal.uniformBuf = pipeline.device.makeBuffer(
            length: MemoryLayout<PlatoUniforms>.stride,
            options: .cpuCacheModeWriteCombined)!
    }
    func makePipeline() {

        let vertexName = "vertexPlato"
        let fragmentName: String
        switch platoStyle {
        case .color   : fragmentName = "fragmentPlatoCubeColor"
        case .reflect : fragmentName = "fragmentPlatoCubeIndex"
        default       : fragmentName = "fragmentPlatoColor"
        }

        let pd = MTLRenderPipelineDescriptor()
        pd.vertexFunction   = library.makeFunction(name: vertexName)
        pd.fragmentFunction = library.makeFunction(name: fragmentName)
        pd.vertexDescriptor = metal.metalVD

        pd.colorAttachments[0].pixelFormat = MetalRenderPixelFormat
        pd.depthAttachmentPixelFormat = .depth32Float

        do {
            renderPipe = try pipeline.device.makeRenderPipelineState(descriptor: pd)
        }
        catch {
            print("⁉️ \(#function) failed to create \(name), error \(error)")
        }
    }
    
    override public func updateUniforms() {

        guard let orientation = Motion.shared.sceneOrientation else { return }

        let perspective = pipeline.perspective()
        let cameraPos = vector_float4([0, 0, -4 * platoFlo.zoom, 1])
        let platoView = translation(cameraPos) * orientation
        let worldCamera = orientation.inverse * -cameraPos
        let projectModel = perspective * (platoView * identity)

        let platoFlo = metal.model.platoFlo

        let range = metal.model.counter.range01
        uniforms = PlatoUniforms(
            range       : range,
            convex      : platoFlo.convex,
            passthru    : platoFlo.passthru,
            shadowWhite : platoFlo.shadowWhite,
            shadowDepth : platoFlo.shadowDepth,
            invert      : platoFlo.invert,
            zoom        : platoFlo.zoom,

            projectModel : projectModel,
            worldCamera  : worldCamera,
            identity     : identity)

        let uniformLen = MemoryLayout<PlatoUniforms>.stride
        memcpy(metal.uniformBuf.contents(), &uniforms, uniformLen)
        metal.updateMetal()
    }
#if os(visionOS)

    /// Update projection and rotation
    override public func updateUniforms(_ layerDrawable: LayerRenderer.Drawable) {

        updateUniforms()
        if let eyeBuf = metal.eyeBuf, let uniforms {
            eyeBuf.updateEyeUniforms(layerDrawable, uniforms.projectModel)
        }

    }
#endif
    override public func renderNode(_ renderCmd: MTLRenderCommandEncoder) {

        guard let cubeNode = pipeline.cubemapNode else { return }
        guard let cubeTex = cubeNode.cubeTex else { return }
        guard let inTex = cubeNode.inTex else { return }
        guard let altTex else { return }

        renderCmd.setTriangleFillMode(platoFlo.wire ? .lines : .fill)
        renderCmd.setRenderPipelineState(renderPipe)
        renderCmd.setVertexBuffer(metal.uniformBuf, offset: 0, index: 1)
        renderCmd.setFragmentBuffer(metal.uniformBuf, offset: 0, index: 1)

        renderCmd.setFragmentTexture(cubeTex, index: 0)
        renderCmd.setFragmentTexture(inTex, index: 1)
        renderCmd.setFragmentTexture(altTex, index: 2)

        renderCmd.setCullMode(.none) // creates artifacts

        renderCmd.setDepthStencilState(pipeline.depthStencil(write: true)) //?????

        metal.drawMesh(renderCmd)
        if metal.model.nextCounter() == true {
            metal.updateMesh()
        }
    }

    override public func updateTextures() {

        altTex = altTex ?? makePaletteTex() // 256 false color palette

        if let altTex,
           let getPal {

            let palSize = 256
            let pixSize = MemoryLayout<UInt32>.size
            let palRegion = MTLRegionMake3D(0, 0, 0, palSize, 1, 1)
            let bytesPerRow = palSize * pixSize
            let palBytes = getPal(palSize)
            altTex.replace(region      : palRegion,
                           mipmapLevel : 0,
                           withBytes   : palBytes,
                           bytesPerRow : bytesPerRow)
        }
        func makePaletteTex() -> MTLTexture? {

            let paletteTex = TextureCache
                .makeTexturePixelFormat(MetalRenderPixelFormat,
                                        size: CGSize(width: 256, height: 1),
                                        device: pipeline.device)
            return paletteTex
        }
        if let cubeNode = inNode as? CubemapNode {
            inTex = cubeNode.cubeTex
        } else {
            inTex = inNode?.outTex
        }
        
    }
}


