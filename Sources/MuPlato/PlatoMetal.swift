// created by musesum on 12/27/23

import MetalKit
import MuVision
import MuExtensions

public class PlatoMetal: MeshMetal {

    var model: PlatoModel!

    init(_ device: MTLDevice) {
        super.init(DepthRendering(
            device,
            immer: RenderDepth(.none, .counterClockwise, .greater, true),
            metal: RenderDepth(.none, .counterClockwise, .less   , true)))

        //  cull   winding           compare write
        // .front .counterClockwise .greater true  //-- not showing
        // .front .counterClockwise .less    true  //-- jumbled
        // .front .counterClockwise .less    false //-- jumbled
        // .front .clockwise        .less    false //-- jumbled
        // .back  .clockwise        .less    false //-- jumbled
        // .back  .counterClockwise .less    true  //-- jumbled
        // .none  .counterClockwise .less    true  //-- metal good!

        // .none  .counterClockwise .less    true) //-- jaggy
        // .back  .counterClockwise .greater true) //-- plato big
        // .none  .counterClockwise .greater true) //-- plato big, flat ok, cube no

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
        updateMesh(device)
    }

    func updateCounter(_ device: MTLDevice) {
        if model.nextCounter() {
            updateMesh(device)
        }
    }
    func updateMetal(_ device: MTLDevice) {

        if model.updateConvex() {
            updateMesh(device)
        }
    }
    func updateMesh(_ device: MTLDevice) {
        mtkMesh = try! MTKMesh(mesh: model.mdlMesh, device: device)
    }
}
