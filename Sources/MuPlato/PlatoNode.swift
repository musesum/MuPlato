//  created by musesum on 3/16/23.

import MetalKit
import MuMetal
import MuVision
import MuFlo

#if os(visionOS)
import CompositorServices
#endif

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

        metal.eyeBuf = UniformEyeBuf(pipeline.device, "Plato", far: false)
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
        
        // alpha blend
        pd.colorAttachments[0].isBlendingEnabled = true
        pd.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pd.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        pd.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        pd.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha

        pd.depthAttachmentPixelFormat = .depth32Float
        #if targetEnvironment(simulator)
        #elseif os(visionOS )
        pd.maxVertexAmplificationCount = 2
        #endif
        do {
            renderPipe = try pipeline.device.makeRenderPipelineState(descriptor: pd)
        }
        catch {
            print("⁉️ \(#function) failed to create \(name), error \(error)")
        }
    }
    
    func updatePlatoUniforms() {

        let platoFlo = metal.model.platoFlo
        
        uniforms = PlatoUniforms(
            range   : metal.model.counter.range01,
            convex  : platoFlo.convex,
            reflect : Float(platoFlo.material.x),
            alpha   : platoFlo.alpha,
            depth   : platoFlo.depth,
            invert  : Float(platoFlo.material.y),
            zoom    : platoFlo.zoom)

        let uniformLen = MemoryLayout<PlatoUniforms>.stride
        memcpy(metal.uniformBuf.contents(), &uniforms, uniformLen)
        metal.updateMetal(pipeline.device)
    }


#if os(visionOS)
    /// Update projection and rotation
    override public func updateUniforms(_ layerDrawable: LayerRenderer.Drawable) {
        updatePlatoUniforms()
        let cameraPos = vector_float4([0, 1, -4 * platoFlo.zoom, 1]) 
        let label = (RenderDepth.state == .immer ? "👁️P⃝lato" : "👁️Plato")
        metal.eyeBuf?.updateEyeUniforms(layerDrawable, cameraPos, label)
    }
#endif
    override public func updateUniforms() {

        updatePlatoUniforms()

        guard let orientation = Motion.shared.sceneOrientation else { return }
        let cameraPos = vector_float4([0, 0, -4 * platoFlo.zoom, 1]) 
        let viewModel = translation(cameraPos) * orientation
        let projection = pipeline.projection()

        MuLog.NoLog("👁️plato", interval: 4) {
            print("\t👁️p projection  ", projection.script)
            print("\t👁️p orientation ", orientation.script)
            print("\t👁️p * cameraPos ", viewModel.script)
        }
        metal.eyeBuf?.updateEyeUniforms(projection, viewModel)
    }

    override public func renderNode(_ renderCmd: MTLRenderCommandEncoder) {

        //?? guard let cubeNode = pipeline.cubemapNode else { return }
        //?? guard let cubeTex = cubeNode.cubeTex else { return }
        //?? guard let inTex = cubeNode.inTex else { return }
        guard let altTex else { return }

        metal.eyeBuf?.setUniformBuf(renderCmd, "Plato")

        renderCmd.setTriangleFillMode(platoFlo.wire ? .lines : .fill)
        renderCmd.setRenderPipelineState(renderPipe)
        renderCmd.setVertexBuffer(metal.uniformBuf, offset: 0, index: 1)
        renderCmd.setFragmentBuffer(metal.uniformBuf, offset: 0, index: 1)

        //?? renderCmd.setFragmentTexture(cubeTex, index: 0) // 1080x1080 //???
        //?? renderCmd.setFragmentTexture(inTex  , index: 1) // 1920x1080 //???
        renderCmd.setFragmentTexture(altTex , index: 2) // 256x1 Palette

        metal.drawMesh(renderCmd)
        metal.updateCounter(pipeline.device)
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
        if let cubeNode = inNode as? CubemapNode {
            inTex = cubeNode.cubeTex
        } else {
            inTex = inNode?.outTex
        }
        func makePaletteTex() -> MTLTexture? {

            let paletteTex = TextureCache
                .makeTexturePixelFormat(MetalRenderPixelFormat,
                                        size: CGSize(width: 256, height: 1),
                                        device: pipeline.device)
            return paletteTex
        }

    }
}


