//  Created by warren on 3/16/23.

import Foundation
import QuartzCore
import Metal
import MuMetal
import simd

struct PlatoUniforms {
    static var size = 64
    var identity     : matrix_float4x4
    var inverse      : matrix_float4x4
    var projectModel : matrix_float4x4
    var worldCamera  : vector_float4
    var range        : Float
    var harmonif     : Float
    var colorCount   : Float
    var colorMix     : Float
    var shadowWhite  : Float
    var shadowDepth  : Float
    var invert       : Float
    var zoom         : Float
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

public class MetNodePlato: MetNode {

    var renderState: MTLRenderPipelineState!
    var palSamplr: MTLSamplerState!
    var uniformBuf: MTLBuffer!

    let platonic: Platonic
    let platoFlo   = PlatoFlo.shared
    let cubeFlo    = CubeFlo.shared
    var platoStyle = PlatoStyle.reflect
    var harmonif  = Float(1) // harmonic factor < 1 concave > 1 convex

    public var getPal: GetTextureFunc?

    public init(_ pipeline: MetPipeline,
                _ getPal: @escaping GetTextureFunc) {

        self.platonic = ((pipeline as? PlatoPipeline)?.platonic
                         ?? Platonic(pipeline.device))
        super.init(pipeline, "plato", "render.plato", .render)
        self.filename = filename
        self.getPal = getPal

        makeLibrary()
        buildResources()
        updateShader()
    }
    
    func buildResources() {

        palSamplr = pipeline.makeSampler(normalized: false)

        uniformBuf = pipeline.device.makeBuffer(
            length: MemoryLayout<PlatoUniforms>.size * 2,
            options: .cpuCacheModeWriteCombined)!
    }
    func updateShader() {

        let vertexName = "plato"

        let fragmentName: String
        switch platoStyle {
            case .color:    fragmentName = "platoCubeColor"
            case .reflect:  fragmentName = "platoCubeIndex"
            default:        fragmentName = "platoColor"
        }

        let vd = MTLVertexDescriptor()
        var offset = 0

        for i in 0 ..< Vert01.count {
            vd.attributes[i].bufferIndex = 0
            vd.attributes[i].offset = offset
            vd.attributes[i].format = .float4
            offset += MemoryLayout<vector_float4>.size
        }
        vd.layouts[0].stepFunction = .perVertex
        vd.layouts[0].stride = MemoryLayout<Vert01>.size
        
        let pd = MTLRenderPipelineDescriptor()
        pd.vertexFunction   = library.makeFunction(name: vertexName)
        pd.fragmentFunction = library.makeFunction(name: fragmentName)
        pd.vertexDescriptor = vd

        pd.colorAttachments[0].pixelFormat = .bgra8Unorm
        pd.depthAttachmentPixelFormat = .depth32Float
        
        do { renderState = try pipeline.device.makeRenderPipelineState(descriptor: pd) }
        catch { print("⁉️ \(#function) failed to create \(name), error \(error)") }
    }

    func updateUniforms() {

        guard let orientation = Motion.shared.sceneOrientation else { return }
        if harmonif != platoFlo.harmonif {
            harmonif = platoFlo.harmonif
            platonic.updateHarmonif(harmonif)
        }
        let perspective = pipeline.perspective()
        let cameraPosition = vector_float4([ 0, 0, -4 * Float(platoFlo.zoom), 1 ])
        let platoView = translation(cameraPosition) * orientation
        let worldCamera = orientation.inverse * -cameraPosition
        let projectModel = perspective * (platoView * identity)

        var platoUniforms = PlatoUniforms(
            identity     : identity,
            inverse      : identity.inverse.transpose,
            projectModel : projectModel,
            worldCamera  : worldCamera,
            range        : platonic.counter.range01,
            harmonif     : platoFlo.harmonif,
            colorCount   : platoFlo.colorCount,
            colorMix     : platoFlo.colorMix,
            shadowWhite  : platoFlo.shadowWhite,
            shadowDepth  : platoFlo.shadowDepth,
            invert       : platoFlo.invert,
            zoom         : platoFlo.zoom)

        let uniformLen = MemoryLayout<PlatoUniforms>.stride
        memcpy(uniformBuf.contents() + uniformLen, &platoUniforms, uniformLen)
    }

    override public func renderCommand(_ renderEnc: MTLRenderCommandEncoder) {

        guard let indexBuf = platonic.platoTris.indexBuf else { return }
        
        let uniformLen = MemoryLayout<PlatoUniforms>.size
        let indexCount = indexBuf.length / MemoryLayout<UInt32>.stride

        renderEnc.setTriangleFillMode(platoFlo.wire ? .lines : .fill)
        renderEnc.setRenderPipelineState(renderState)
        renderEnc.setDepthStencilState(pipeline.depthStencil(write: true))
        
        renderEnc.setVertexBuffer(platonic.platoTris.vertexBuf, offset: 0, index: 0)
        renderEnc.setVertexBuffer(uniformBuf, offset: uniformLen, index: 1)
        renderEnc.setFragmentBuffer(uniformBuf, offset: uniformLen, index: 1)

        guard let cubeNode   = pipeline.cubemapNode else { return }
        guard let cubeTex    = cubeNode.cubeTex else { return }
        guard let cubeSamplr = cubeNode.cubeSamplr else { return }
        renderEnc.setFragmentTexture(cubeTex, index: 0)
        renderEnc.setFragmentSamplerState(cubeSamplr, index: 0)

        guard let inTex    = cubeNode.inTex    else { return }
        guard let inSamplr = cubeNode.inSamplr else { return }
        renderEnc.setFragmentTexture(inTex, index: 1)
        renderEnc.setFragmentSamplerState(inSamplr, index: 1)

        guard let altTex else { return }
        renderEnc.setFragmentTexture(altTex, index: 2)
        renderEnc.setFragmentSamplerState(palSamplr, index: 2)
        #if true
        renderEnc.drawPrimitives(type: .triangle,
                                 vertexStart: 0,
                                 vertexCount: indexCount)
        #else
        renderEnc.drawIndexedPrimitives(
            type              : .triangle,
            indexCount        : indexCount,
            indexType         : .uint32,
            indexBuffer       : indexBuf,
            indexBufferOffset : 0)
        #endif
        platonic.nextCounter()
    }

    override public func setupInOutTextures(via: String) {

        updateUniforms()
        altTex = altTex ?? makePaletteTex() // 256 false color palette

        if let altTex,
           let getPal {

            let palSize = 256
            let pixSize = MemoryLayout<UInt32>.size
            let palRegion = MTLRegionMake3D(0, 0, 0, palSize, 1, 1)
            let bytesPerRow = palSize * pixSize
            let palBytes = getPal(palSize)
            altTex.replace(region: palRegion,
                           mipmapLevel: 0,
                           withBytes: palBytes,
                           bytesPerRow: bytesPerRow)
        }
        func makePaletteTex() -> MTLTexture? {

            let paletteTex = MetTexCache
                .makeTexturePixelFormat(.bgra8Unorm,
                                        size: CGSize(width: 256, height: 1),
                                        device: pipeline.device)
            return paletteTex
        }
        if let cubeNode = inNode as? MetNodeCubemap {
            inTex = cubeNode.cubeTex
        } else {
            inTex = inNode?.outTex
        }
        
    }
}


