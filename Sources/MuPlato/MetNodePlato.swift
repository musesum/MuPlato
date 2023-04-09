//  Created by warren on 3/16/23.

import Foundation
import QuartzCore
import Metal
import MuMetal
import simd

struct PlatoUniforms {
    var identity     : matrix_float4x4
    var inverse      : matrix_float4x4
    var projectModel : matrix_float4x4
    var worldCamera  : vector_float4
    var range01      : vector_float4
}

public class MetNodePlato: MetNode {

    var renderState: MTLRenderPipelineState!
    var samplerState: MTLSamplerState!
    var uniformBuf: MTLBuffer!

    let platonic: Platonic
    let platoOps: PlatoOps
    let platoPipe: PlatoPipeline

    init(_ pipeline: PlatoPipeline,
         _ filename: String = "pipe.plato") {

        self.platoPipe = pipeline
        self.platonic = pipeline.platonic
        self.platoOps = pipeline.platonic.platoOps
        super.init(pipeline, "plato", "pipe.plato", .render)
        self.filename = filename

        buildShader()
        buildResources()
    }
    
    func buildResources() {
        
        uniformBuf = pipeline.device.makeBuffer(
            length: MemoryLayout<PlatoUniforms>.size * 2,
            options: .cpuCacheModeWriteCombined)!
    }

    func buildShader() {

        makeLibrary()

        let vertexName = "platoVertex"
        let fragmentName = (platoOps.reflectCube
                            ? (platoOps.hasCamera
                               ? "cubeIndexFragment"
                               : "cubeColorFragment")
                            : "colorFragment")
        
        let vd = MTLVertexDescriptor()
        var offset = 0
        
        for i in 0 ..< 6 {
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
        catch { print("🚫 \(#function) failed to create \(name), error \(error)") }
    }

    func updateUniforms() {

        guard let orientation = Motion.shared.sceneOrientation else { return }
        let perspective = pipeline.perspective()
        let cameraPosition = vector_float4([ 0, 0, -4, 1 ])
        let platoView = translation(cameraPosition) * orientation
        let worldCamera = orientation.inverse * -cameraPosition
        let projectModel = perspective * (platoView * identity)

        var platoUniforms = PlatoUniforms(
            identity: identity,
            inverse: identity.inverse.transpose,
            projectModel: projectModel,
            worldCamera: worldCamera,
            range01: platonic.ranges())

        let uniformLen = MemoryLayout<PlatoUniforms>.stride
        memcpy(uniformBuf.contents() + uniformLen, &platoUniforms, uniformLen)
    }

    override public func renderCommand(_ renderEnc: MTLRenderCommandEncoder) {

        guard let indexBuf = platonic.plaTrii.indexBuf else { return }

        let uniformLen = MemoryLayout<PlatoUniforms>.size
        let indexCount = indexBuf.length / MemoryLayout<UInt32>.stride

        renderEnc.setTriangleFillMode(platoOps.drawFill ? .fill : .lines)
        renderEnc.setRenderPipelineState(renderState)
        renderEnc.setDepthStencilState(pipeline.depthStencil(write: true))
        
        renderEnc.setVertexBuffer(platonic.plaTrii.vertexBuf, offset: 0, index: 0)
        renderEnc.setVertexBuffer(uniformBuf, offset: uniformLen, index: 1)
        renderEnc.setFragmentBuffer(uniformBuf, offset: uniformLen, index: 0)
        
        if let cubemapNode = platoPipe.cubemapNode {
            if platoOps.reflectCube,
               let cubeTex    = cubemapNode.cubeTex,
               let cubeSamplr = cubemapNode.cubeSamplr {
                
                renderEnc.setFragmentTexture(cubeTex, index: 0)
                renderEnc.setFragmentSamplerState(cubeSamplr, index: 0)
            }
            if platoOps.hasCamera {
                guard let imageTex    = cubemapNode.inTex    else { return }
                guard let imageSamplr = cubemapNode.inSamplr else { return }
                
                renderEnc.setFragmentTexture(imageTex, index: 1)
                renderEnc.setFragmentSamplerState(imageSamplr, index: 1)
            }
        }
        
        renderEnc.drawIndexedPrimitives(
            type: .triangle,
            indexCount: indexCount,
            indexType: .uint32,
            indexBuffer: indexBuf,
            indexBufferOffset: 0)

        platonic.nextCounter()
    }

    override public func setupInOutTextures(via: String) {

        updateUniforms()
        inTex = inNode?.outTex
    }
}


