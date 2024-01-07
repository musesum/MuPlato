// created by musesum on 12/27/23

import MetalKit
import MuVision

public class PlatoMetal: MeshMetal {

    var model: PlatoModel!

    init(_ device: MTLDevice) {

        //  compare write  cull   winding
        // .greater true  .front .counterClockwise -- not showing
        // .less    true  .front .counterClockwise -- jumbled
        // .less    false .front .counterClockwise -- jumbled
        // .less    false .front .clockwise        -- jumbled
        // .less    false .back  .clockwise        -- jumbled
        // .less    true  .back  .counterClockwise -- jumbled
        // .less    true  .none  .counterClockwise -- metal good!

        super.init(device, cull: .none, winding: .counterClockwise)
        self.stencil = MeshMetal.stencil(device, .less, true)

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
    func updateMetal() {

        if model.updateConvex() {
            updateMesh()
        }
    
    }
    func updateMesh() {
        mtkMesh = try! MTKMesh(mesh: model.mdlMesh, device: device) 
    }
}
