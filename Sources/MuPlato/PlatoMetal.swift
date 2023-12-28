// created by musesum on 12/27/23

import MetalKit
import MuVision

public class PlatoMetal: MeshMetal {

    var model: PlatoModel!

    init(_ device: MTLDevice) {

        super.init(device: device, compare: .greater, winding: .clockwise)

        let nameFormats: [VertexNameFormat] = [
            ("pos0"    , .float4),
            ("pos1"    , .float4),
            ("norm0"   , .float4),
            ("norm1"   , .float4),
            ("vertId"  , .float),
            ("faceId"  , .float),
            ("harmonic", .float),
            ("phase"   , .float),
        ]
        let vertexStride = MemoryLayout<PlatoVertex>.stride
        model = PlatoModel(device, nameFormats, vertexStride)
        makeMetalVD(nameFormats,vertexStride)
        updateMesh()
    }
    func updateUniforms() {

        if model.updateConvex() {
            updateMesh()
        }
    }
    func updateMesh() {
        mtkMesh = try! MTKMesh(mesh: model.mdlMesh, device: device) 
    }
}
