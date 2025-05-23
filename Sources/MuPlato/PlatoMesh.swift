// created by musesum on 12/27/23

import MetalKit
import MuVision
import MuFlo

public class PlatoMesh: MeshMetal {

    var model: PlatoModel!

    init(_ platoFlo: PlatoFlo,
         _ renderState: RenderState) {
        let immersed = RenderDepth(.none, .counterClockwise, .greaterEqual, true) // back hidden
        let windowed = RenderDepth(.none, .counterClockwise, .less,         true)
        let depthRendering = DepthRendering(immersed, windowed, renderState)
        super.init(depthRendering)

        let nameFormats: [VertexNameFormat] = [
            ("pos0",     .float4),
            ("pos1",     .float4),
            ("norm0",    .float4),
            ("norm1",    .float4),
            ("vertId",   .float),
            ("faceId",   .float),
            ("harmonic", .float),
            ("phase",    .float),
        ]
        let vertexStride = MemoryLayout<PlatoVertex>.stride
        model = PlatoModel(platoFlo, nameFormats, vertexStride)
        makeMetalVD(nameFormats,vertexStride)
        updateMesh()
    }

    func updateCounter() {
        if model.nextCounter() {
            updateMesh()
        }
    }
    func updateMetal() {
        if model.updateConvex() {
            updateMesh()
        }
    }
    func updateMesh() {
        guard let device = MTLCreateSystemDefaultDevice() else { return }
        mtkMesh = try! MTKMesh(mesh: model.mdlMesh, device: device)
    }
}
