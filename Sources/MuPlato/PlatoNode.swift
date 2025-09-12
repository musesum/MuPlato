//  created by musesum on 3/16/23.

import MetalKit
import MuVision
import MuFlo

#if os(visionOS)
import CompositorServices
#endif

public class PlatoNode: RenderNode, @unchecked Sendable {

    var platoMesh    : PlatoMesh!
    var platoShading : PlatoShading!
    let platoFlo     : PlatoFlo
    var platoStyle   = PlatoStyle.reflect

    private var inTex˚   : Flo?
    private var cubeTex˚ : Flo?
    private var palTex˚  : Flo?
    private var range01˚ : Flo?
    private var shading˚ : Flo?

    public override init(_ pipeline : Pipeline,
                         _ pipeNode˚ : Flo) {

        platoFlo = PlatoFlo(pipeline.root˚)
        platoMesh = PlatoMesh(platoFlo, pipeline.renderState)
        super.init(pipeline, pipeNode˚)
        inTex˚   = pipeNode˚.superBindPath("in")
        palTex˚  = pipeNode˚.superBindPath("pal")
        cubeTex˚ = pipeNode˚.superBindPath("cube")
        range01˚ = pipeNode˚.superBindPath("range01")
        shading˚ = pipeNode˚.superBindPath("shading")
    }

    override public func makePipeline() {
        shader = Shader(pipeline,
                        file: "render.plato",
                        vertex: "platoVertex",
                        fragment: "platoFragment")

        renderPipelineState = makeRenderState(platoMesh.mtlVD)
    }
    override public func makeResources() {

        platoMesh.mtlBuffer = pipeline.device.makeBuffer(
            length: MemoryLayout<PlatoShading>.stride,
            options: .cpuCacheModeWriteCombined)!
        platoMesh.mtlBuffer?.label = "PlatoMesh"
        platoMesh.eyeBuf = EyeBuf("PlatoEyes", far: false)

        range01˚?.updateMtlBuffer()
        shading˚?.buffer = platoMesh.mtlBuffer
    }



    override open func updateUniforms() {

        updatePlato()
        Task {
            let orientation = await Motion.shared.updateDeviceOrientation()

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
    }
    func updatePlato() {

        platoMesh.updateMetal()
        let platoFlo = platoMesh.model.platoFlo

        platoShading = PlatoShading(
            convex  : platoFlo.convex,
            reflect : Float(platoFlo.material.y),
            alpha   : Float(platoFlo.alpha),
            depth   : Float(platoFlo.material.x),
            invert  : Float(1),//....(platoFlo.material.z),
            zoom    : platoFlo.zoom            )

        let size = MemoryLayout<PlatoShading>.stride
        memcpy(platoMesh.mtlBuffer.contents(), &platoShading, size)
        let range01 = Double(platoMesh.model.counter.range01)
        range01˚?.setNameNums([("x",range01)],[],Visitor(0))
    }

    override public func renderShader(_ renderEnc: MTLRenderCommandEncoder,
                                      _ renderState: RenderState) {
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

        platoMesh.drawMesh(renderEnc, renderState)
        platoMesh.updateCounter()
    }
    
#if os(visionOS)
    /// Update projection and rotation
    override public func updateUniforms(
        _ drawable : LayerRenderer.Drawable,
        _ anchor   : DeviceAnchor?) {

        updatePlato()

            let cameraPos = vector_float4([0, 1, 4 * (platoFlo.zoom - 1), 1])
        platoMesh.eyeBuf?.updateEyeUniforms(drawable, anchor, cameraPos, "👁️Plato")
    }
#endif

}
