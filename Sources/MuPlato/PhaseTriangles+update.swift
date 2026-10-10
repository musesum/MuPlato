//  created by musesum on 2/22/23.

import Foundation
import Metal
import Vision
import UIKit
import simd
import MuFlo

extension PhaseTriangles {

    func updateTriangles(_ convex: Float, _ phase: Int, smooth: Float = 0) {

        vertices = [PlatoVertex](repeating: PlatoVertex(), count: triCount)
        indices =  [UInt32]     (repeating:             0, count: triCount)
        var index = 0
        
        if PhaseTriangles.logVertex { print() }

        for tri in triRanges {

            for vert in [tri.v0, tri.v1, tri.v2] {

                let harmonic = Float(vert.harmonic)
                let convex = pow(convex, harmonic)
                vertices[index].pos0 = pnt4f(vert.p0, 1) * convex
                vertices[index].pos1 = pnt4f(vert.p1, 1) * convex
                vertices[index].vertId = Float(vert.id)   
                vertices[index].faceId = Float(tri.id)
                vertices[index].harmonic = Float(vert.harmonic)
                vertices[index].phase = Float(phase)

                indices[index] = UInt32(index)
                if PhaseTriangles.logVertex {
                    logVert01(vertices[index], index)
                }
                index += 1
            }

            let n0 = normalize(vertices[index-3].pos0.xyz,
                               vertices[index-2].pos0.xyz,
                               vertices[index-1].pos0.xyz)
            
            vertices[index-3].norm0 = n0
            vertices[index-2].norm0 = n0
            vertices[index-1].norm0 = n0

            let n1 = normalize(vertices[index-3].pos1.xyz,
                               vertices[index-2].pos1.xyz,
                               vertices[index-1].pos1.xyz)
            vertices[index-3].norm1 = n1
            vertices[index-2].norm1 = n1
            vertices[index-1].norm1 = n1
        }
        setNormals(smooth)
    }
    /// norm0/norm1.xyz = the unit normal at each end of the morph: the face
    /// normal when blend is 0, else the area-weighted sum of the outward face
    /// normals at the welded position. norm.w carries the blend: the shader
    /// mixes its live face normal (from the three morphed corners) into this
    /// vertex normal by w, so the face part follows the drawn triangle at
    /// every range01 and the vertex part is shared by coincident corners.
    /// a sum that cancels to zero (back-to-back slivers where the tables
    /// fold) falls back to the radial direction, which every corner at that
    /// position shares, so no seam opens there. a triangle with no area at
    /// an end before the convex pull (a trisected sliver) adds nothing there
    func setNormals(_ blend: Float) {
        let blend = min(max(blend, 0), 1)
        guard blend > 0 else {
            for i in vertices.indices {
                let v = vertices[i]
                vertices[i].norm0 = pnt4f(unit(v.norm0.xyz, v.pos0.xyz), 0)
                vertices[i].norm1 = pnt4f(unit(v.norm1.xyz, v.pos1.xyz), 0)
            }
            return
        }
        var sum0 = [String: SIMD3<Float>]()
        var sum1 = [String: SIMD3<Float>]()
        for t in stride(from: 0, to: vertices.count - 2, by: 3) {
            let (a, b, c) = (vertices[t], vertices[t+1], vertices[t+2])
            let tri = triRanges[t / 3]
            if hasArea(tri.v0.p0, tri.v1.p0, tri.v2.p0) {
                let n0 = outward(a.pos0.xyz, b.pos0.xyz, c.pos0.xyz)
                for v in [a, b, c] { sum0[PlatoSprings.weldKey(v.pos0), default: .zero] += n0 }
            }
            if hasArea(tri.v0.p1, tri.v1.p1, tri.v2.p1) {
                let n1 = outward(a.pos1.xyz, b.pos1.xyz, c.pos1.xyz)
                for v in [a, b, c] { sum1[PlatoSprings.weldKey(v.pos1), default: .zero] += n1 }
            }
        }
        for i in vertices.indices {
            let v = vertices[i]
            let vert0 = unit(sum0[PlatoSprings.weldKey(v.pos0)] ?? .zero, v.pos0.xyz)
            let vert1 = unit(sum1[PlatoSprings.weldKey(v.pos1)] ?? .zero, v.pos1.xyz)
            vertices[i].norm0 = pnt4f(vert0, blend)
            vertices[i].norm1 = pnt4f(vert1, blend)
        }
    }
    /// the corners span an area before the convex pull
    func hasArea(_ v0: SIMD3<Float>,
                 _ v1: SIMD3<Float>,
                 _ v2: SIMD3<Float>) -> Bool {
        simd_length(simd_cross(v1 - v0, v2 - v0)) > 1e-5
    }
    /// raw cross product (length = 2× area) turned away from the origin;
    /// the solids are star-shaped about it
    func outward(_ v0: SIMD3<Float>,
                 _ v1: SIMD3<Float>,
                 _ v2: SIMD3<Float>) -> SIMD3<Float> {
        let n = simd_cross(v1-v0, v2-v0)
        return simd_dot(n, v0+v1+v2) < 0 ? -n : n
    }
    /// unit v, else unit fallback, else zero -- never NaN
    func unit(_ v: SIMD3<Float>, _ fallback: SIMD3<Float>) -> SIMD3<Float> {
        let l = simd_length(v)
        if l > 1e-9 { return v / l }
        let fl = simd_length(fallback)
        return fl > 1e-9 ? fallback / fl : .zero
    }
    func normalize(_ v0: SIMD3<Float>,
                   _ v1: SIMD3<Float>,
                   _ v2: SIMD3<Float>) -> SIMD4<Float> {

        let u = unit(outward(v0, v1, v2), .zero)
        return SIMD4<Float>(u.x, u.y, u.z, 0)
    }
}
