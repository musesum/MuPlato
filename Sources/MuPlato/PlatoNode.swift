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
    
    override public func makeShader() {
        shader = Shader(pipeline, "render.plato",
                        vertex: "platoVertex",
                        fragment: "platoFragment")
        
        renderPipelineState = makeRenderState(platoMesh.mtlVD)
    }
    override public func makeResources() {
        
        platoMesh.mtlBuffer = pipeline.device.makeBuffer(
            length: MemoryLayout<PlatoShading>.stride,
            options: .cpuCacheModeWriteCombined)!
        platoMesh.mtlBuffer?.label = "PlatoMesh"
        platoMesh.eyeBuf = EyeBuf("PlatoEyes", pipeline, far: false)
        
        range01˚?.updateMtlBuffer()
        shading˚?.buffer = platoMesh.mtlBuffer
    }
    override open func updateUniforms() {
        
        updatePlato()
        Task {
            let orientation = await Motion.shared.updateDeviceOrientation()
            // the cube's view: plato turns and zooms with plato.cube
            let nav = CubeNav.shared
            let eyeZ = 4 - 4 * platoFlo.zoom // zoom walks the eye in
            let cameraPos = vector_float4([0, 0, -eyeZ, 1])
            let viewModel = translate4x4(cameraPos) * nav.view(orientation)
            platoMesh.eyeBuf?.updateMetalEyeUniforms(viewModel, distance: 4, eyeDistance: eyeZ,
                                                     frustum: platoFlo.frustum, zoom: nav.zoom)
        }
    }

    /// canvas touch began, in view points: true when the sight ray meets the
    /// object — the stroke is muted for that touch and, with the spring
    /// above zero, the springs take the impulse at the hit point
    public func touchBegan(_ point: CGPoint) -> Bool {
        guard pipeFlo˚.val("on") ?? 0 > 0,
              let hit = hitPoint(point) else { return false }
        if platoFlo.spring > 0 {
            platoMesh.model.springs?.impulse(at: hit)
        }
        return true
    }
    func updatePlato() {
        
        platoMesh.updateMetal()
        platoMesh.updateSprings()
        let platoFlo = platoMesh.model.platoFlo
        
        platoShading = PlatoShading(
            convex  : platoFlo.convex,
            reflect : Float(platoFlo.material.y),
            alpha   : Float(platoFlo.alpha),
            // the menu's opacity reads the way it sounds: 1 opaque, 0 the
            // most see-through, which is the shading's own depth run backwards
            depth   : Float(1 - platoFlo.material.x),
            invert  : Float(1), //....(platoFlo.material.z),
            zoom    : platoFlo.zoom            )
        
        let size = MemoryLayout<PlatoShading>.stride
        memcpy(platoMesh.mtlBuffer.contents(), &platoShading, size)
        let range01 = Double(platoMesh.model.counter.range01)
        range01˚?.setNameNums([("x",range01)],[],Visitor(0))
    }
    
    override public func renderShader(_ encoder: MTLRenderCommandEncoder,
                                      _ state: RenderState) {
        guard let renderPipelineState else { return }
        
        platoMesh.eyeBuf?.setUniformBuf(encoder)
        
        range01˚?.updateMtlBuffer()
        shading˚?.updateMtlBuffer()
        
        encoder.setFragmentTexture (inTex˚,    index: 0)
        encoder.setFragmentTexture (palTex˚,   index: 2)
        encoder.setFragmentTexture (cubeTex˚,  index: 4)
        encoder.setVertexBuffer    (range01˚,  index: 1)
        encoder.setFragmentBuffer  (shading˚,  index: 1)
        encoder.setTriangleFillMode(platoFlo.wire ? .lines : .fill)
        encoder.setRenderPipelineState(renderPipelineState)
        
        platoMesh.drawMesh(encoder, state)
        platoMesh.updateCounter()
    }
    public override func logShader(_ logging: inout String,
                                   _ inOut: String) {

        let inAdr = inTex˚?.texPtr ?? ""
        let inOut = "(\(inAdr))"
        super.logShader(&logging, inOut)
    }

#if os(visionOS)
    /// Update projection and rotation
    override public func updateUniforms(
        _ drawable : LayerRenderer.Drawable,
        _ anchor   : DeviceAnchor?) {
            
            updatePlato()
            platoMesh.eyeBuf?.updateVisionEyeUniforms(drawable, anchor, platoFlo.zoom, "👁️Plato")
        }
#endif
    
}
