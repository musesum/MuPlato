// created by musesum on 12/27/23

import MetalKit
import MuVision
import MuFlo

public class PlatoMesh: MeshMetal {

    var model: PlatoModel!

    init(_ platoFlo: PlatoFlo,
         _ renderState: RenderState) {
        
        let immersed = RenderDepth(cull    : .none,
                                   winding : .counterClockwise,
                                   compare : .greaterEqual,
                                   write   : true) // back hidden

        let windowed = RenderDepth(cull    : .none,
                                   winding : .counterClockwise,
                                   compare : .less,
                                   write   : true)
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
        springsWritten = false
    }

    var springsWritten = false // vertex buffer carries spring offsets

    /// spring above zero: step the relaxation and write displaced positions
    /// and normals into the vertex buffer; at zero no step runs (impulses
    /// dropped) and the built vertices are restored once
    func updateSprings() {
        guard let springs = model.springs,
              let vb = mtkMesh?.vertexBuffers.first else { return }
        let balloon = model.platoFlo.spring
        let on = balloon > 0
        if !on && !springsWritten { return }
        let count = model.vertices.count
        // drawMesh binds this buffer at vb.offset, so the writes start there too
        let base = (vb.buffer.contents() + vb.offset).bindMemory(to: PlatoVertex.self, capacity: count)
        if on {
            springs.step(balloon: balloon, range01: model.counter.range01)
            let blend = min(max(model.platoFlo.normal, 0), 1)
            for i in 0 ..< count {
                let d = springs.offset(i)
                let n = springs.vertexNormal(i)
                var v = model.vertices[i]
                v.pos0 += SIMD4<Float>(d.x, d.y, d.z, 0)
                v.pos1 += SIMD4<Float>(d.x, d.y, d.z, 0)
                v.norm0 = SIMD4<Float>(n.x, n.y, n.z, blend) // w: face → vertex
                v.norm1 = v.norm0
                base[i] = v
            }
            springsWritten = true
        } else {
            springs.reset()
            for i in 0 ..< count { base[i] = model.vertices[i] }
            springsWritten = false
        }
    }
}
