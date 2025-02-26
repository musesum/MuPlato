//  created by musesum on 3/16/23.

import MetalKit
import MuVision
import MuFlo

#if os(visionOS)
import CompositorServices
#endif

public class PlatoNode: RenderNode {

    var platoMesh    : PlatoMesh!
    var platoShading : PlatoShading!
    let platoFlo     = PlatoFlos.shared
    var platoStyle   = PlatoStyle.reflect

    private var inTex˚   : Flo?
    private var cubeTex˚ : Flo?
    private var palTex˚  : Flo?
    private var range01˚ : Flo?
    private var shading˚ : Flo?

    public override init(_ pipeline : Pipeline,
                         _ childFlo : Flo) {

        super.init(pipeline, childFlo)
        platoMesh = PlatoMesh()
        inTex˚   = pipeFlo.superBindPath("in")
        palTex˚  = pipeFlo.superBindPath("pal")
        cubeTex˚ = pipeFlo.superBindPath("cube")
        range01˚ = pipeFlo.superBindPath("range01")
        shading˚ = pipeFlo.superBindPath("shading")

        makeRenderPipeline()
        makeResources()
    }
    
    func makeRenderPipeline() {
        shader = Shader(pipeline,
                        file: "render.plato",
                        vertex: "platoVertex",
                        fragment: "platoFragment")

        renderPipelineState = makeRenderState(platoMesh.metalVD)
    }
    override open func makeResources() {

        platoMesh.mtlBuffer = pipeline.device.makeBuffer(
            length: MemoryLayout<PlatoShading>.stride,
            options: .cpuCacheModeWriteCombined)!
        platoMesh.mtlBuffer?.label = "PlatoMesh"
        platoMesh.eyeBuf = EyeBuf("PlatoEyes", far: false)

        range01˚?.updateMtlBuffer()
        shading˚?.buffer = platoMesh.mtlBuffer
        super.makeResources()
    }

    func updatePlatoUniforms() {

        platoMesh.updateMetal()
        let platoFlos = platoMesh.model.platoFlos

        platoShading = PlatoShading(
            convex  : platoFlos.convex,            // platoFlos.convex,
            reflect : Float(platoFlos.material.y), // Float(platoFlos.material.x),
            alpha   : Float(platoFlos.material.z), // platoFlos.alpha,
            depth   : Float(platoFlos.material.x), // platoFlos.depth,
            invert  : Float(platoFlos.material.z), // Float(platoFlos.material.y),
            zoom    : platoFlos.zoom            )  // platoFlos.zoom)

        let size = MemoryLayout<PlatoShading>.stride
        memcpy(platoMesh.mtlBuffer.contents(), &platoShading, size)
        range01˚?.updateFloScalars(platoMesh.model.counter.range01)
    }

    override open func updateUniforms() {

        updatePlatoUniforms()

        guard let orientation = Motion.shared.sceneOrientation else { return }
        let cameraPos = vector_float4([0, 0, 4 * (platoFlo.zoom - 1), 1])
        let viewModel = translate4x4(cameraPos) * orientation
        let projection = project4x4(pipeline.layer.drawableSize)

        platoMesh.eyeBuf?.updateEyeUniforms(projection, viewModel)

        NoTimeLog("👁️plato", interval: 4) {
            print("\t👁️p projection  ", projection.digits())
            print("\t👁️p orientation ", orientation.digits())
            print("\t👁️p * cameraPos ", viewModel.digits())
        }
    }

    override public func renderNode(_ renderEnc: MTLRenderCommandEncoder) {
        guard let renderPipelineState else { return }

        platoMesh.eyeBuf?.setUniformBuf(renderEnc)

        range01˚?.updateMtlBuffer()
        shading˚?.updateMtlBuffer()

        renderEnc.setFragmentTexture (inTex˚,    index: 0)
        renderEnc.setFragmentTexture (palTex˚,   index: 2)
        renderEnc.setFragmentTexture (cubeTex˚,  index: 4)
        renderEnc.setVertexBuffer    (range01˚,  index: 1)
        renderEnc.setFragmentBuffer  (shading˚,  index: 1)
        renderEnc.setTriangleFillMode(platoFlo.wire ? .lines : .fill)
        renderEnc.setRenderPipelineState(renderPipelineState)

        platoMesh.drawMesh(renderEnc)
        platoMesh.updateCounter()
    }
    
#if os(visionOS)
    /// Update projection and rotation
    override public func updateUniforms(_ drawable: LayerRenderer.Drawable) {

        updatePlatoUniforms()
        
        let cameraPos = vector_float4([0, 1, 4 * (platoFlo.zoom - 1), 1])
        let label = (RenderDepth.state == .immersive ? "👁️P⃝lato" : "👁️Plato")
        platoMesh.eyeBuf?.updateEyeUniforms(drawable, cameraPos, label)
    }
#endif

}
