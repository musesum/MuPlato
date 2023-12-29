//  created by musesum on 3/16/23.

import MetalKit
import MuMetal
import MuVision

struct PlatoUniforms {
    var range        : Float
    var depth        : Float
    var passthru     : Float
    var shadowWhite  : Float
    var shadowDepth  : Float
    var invert       : Float
    var zoom         : Float
    var projectModel : matrix_float4x4
    var worldCamera  : vector_float4
    var identity     : matrix_float4x4
    var inverse      : matrix_float4x4
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

    var platoMetal : PlatoMetal!
    var uniformBuf : MTLBuffer!
    let platoFlo   = PlatoFlo.shared
    let cubeFlo    = CubeFlo.shared
    var platoStyle = PlatoStyle.reflect

    public var getPal: GetTextureFunc?

    public init(_ pipeline: Pipeline,
                _ getPal: @escaping GetTextureFunc) {
        
        super.init(pipeline, "plato", "render.plato", .rendering)
        self.platoMetal = PlatoMetal(pipeline.device)
        self.filename = filename
        self.getPal = getPal

        makeLibrary()
        makeResources()
        makePipeline()
    }

    func makeResources() {

        uniformBuf = pipeline.device.makeBuffer(
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
        pd.vertexDescriptor = platoMetal.metalVD

        pd.colorAttachments[0].pixelFormat = .bgra8Unorm
        pd.depthAttachmentPixelFormat = .depth32Float

        do {
            renderPipe = try pipeline.device.makeRenderPipelineState(descriptor: pd)
        }
        catch {
            print("⁉️ \(#function) failed to create \(name), error \(error)")
        }
    }
    
    func updateUniforms() {

        guard let orientation = Motion.shared.sceneOrientation else { return }

        let perspective = pipeline.perspective()
        let cameraPos = vector_float4([0, 0, -4 * platoFlo.zoom, 1])
        let platoView = translation(cameraPos) * orientation
        let worldCamera = orientation.inverse * -cameraPos
        let projectModel = perspective * (platoView * identity)

        let platoFlo = platoMetal.model.platoFlo

        let range = platoMetal.model.counter.range01
        var platoUniforms = PlatoUniforms(
            range       : range,
            depth       : platoFlo.convex,
            passthru    : platoFlo.passthru,
            shadowWhite : platoFlo.shadowWhite,
            shadowDepth : platoFlo.shadowDepth,
            invert      : platoFlo.invert,
            zoom        : platoFlo.zoom,

            projectModel : projectModel,
            worldCamera  : worldCamera,
            identity     : identity,
            inverse      : identity.inverse.transpose)

        let uniformLen = MemoryLayout<PlatoUniforms>.stride
        memcpy(uniformBuf.contents(), &platoUniforms, uniformLen)
        platoMetal.updateMetal()
    }

    override public func renderNode(_ renderCmd: MTLRenderCommandEncoder) {

        guard let cubeNode = pipeline.cubemapNode else { return }
        guard let cubeTex = cubeNode.cubeTex else { return }
        guard let inTex = cubeNode.inTex else { return }
        guard let altTex else { return }

        renderCmd.setTriangleFillMode(platoFlo.wire ? .lines : .fill)
        renderCmd.setRenderPipelineState(renderPipe)
        renderCmd.setVertexBuffer(uniformBuf, offset: 0, index: 1)
        renderCmd.setFragmentBuffer(uniformBuf, offset: 0, index: 1)

        renderCmd.setFragmentTexture(cubeTex, index: 0)
        renderCmd.setFragmentTexture(inTex, index: 1)
        renderCmd.setFragmentTexture(altTex, index: 2)

        renderCmd.setCullMode(.none) // creates artifacts

        renderCmd.setDepthStencilState(pipeline.depthStencil(write: true))

        platoMetal.drawMesh(renderCmd)
        if platoMetal.model.nextCounter() == true {
            platoMetal.updateMesh()
        }
    }

    override public func updateTextures() {

        updateUniforms()
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
                .makeTexturePixelFormat(.bgra8Unorm,
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


