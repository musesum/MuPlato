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

    /// the ico ball steps every frame; a platonic solid only while the
    /// clock is off, and there only while pressed or ringing down, so at
    /// rest it draws its built vertices
    static func springsOn(balloon: Float, deforms: Bool, pressed: Bool, active: Bool) -> Bool {
        balloon > 0 || (deforms && (pressed || active))
    }

    /// springs on: step the relaxation, held presses sunk up to pressDepth
    /// ball radii, and write displaced positions into the vertex buffer,
    /// with the ball's own normals; a platonic solid keeps its built normals
    /// and the shader's face normals show the dent. Off: no step runs
    /// (impulses dropped, presses ignored) and the built vertices are
    /// restored once
    func updateSprings(presses: [SpringPress] = [], pressDepth: Float = 0) {
        guard var springs = model.springs,
              let vb = mtkMesh?.vertexBuffers.first else { return }
        let balloon = model.platoFlo.spring
        let on = Self.springsOn(balloon: balloon, deforms: model.platoFlo.deforms,
                                pressed: !presses.isEmpty, active: springs.active)
        if !on && !springsWritten { return }
        let count = model.vertices.count
        // drawMesh binds this buffer at vb.offset, so the writes start there too
        let base = (vb.buffer.contents() + vb.offset).bindMemory(to: PlatoVertex.self, capacity: count)
        if on {
            // the clock may have run since these springs were built: a solid
            // starts again where it stopped
            if springs.solid, springs.builtAt != model.counter.range01 {
                let was = springs
                springs = model.solidSprings()
                springs.adopt(was)
            }
            springs.step(balloon: balloon, range01: model.counter.range01,
                         presses: presses, pressDepth: pressDepth)
            let blend = min(max(model.platoFlo.normal, 0), 1)
            let ball = balloon > 0
            for i in 0 ..< count {
                let d = springs.offset(i)
                var v = model.vertices[i]
                v.pos0 += SIMD4<Float>(d.x, d.y, d.z, 0)
                v.pos1 += SIMD4<Float>(d.x, d.y, d.z, 0)
                if ball {
                    let n = springs.vertexNormal(i)
                    v.norm0 = SIMD4<Float>(n.x, n.y, n.z, blend) // w: face → vertex
                    v.norm1 = v.norm0
                }
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
