//  created by musesum on 2/22/23.

import Foundation
import Metal
import Vision
import UIKit
import simd
import MuFlo

extension PhaseTriangles {

    func updateTriangles(_ phase: Int) {

        vertices = [PlatoVertex](repeating: PlatoVertex(), count: triCount)
        indices =  [UInt32]     (repeating:             0, count: triCount)
        var index = 0
        
        if PhaseTriangles.logVertex { print() }

        for tri in triRanges {

            for vert in [tri.v0, tri.v1, tri.v2] {

                let harmonic = Float(vert.harmonic)
                let convex = pow(PlatoFlo.shared.convex, harmonic)
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
    }
    func normalize(_ v0: SIMD3<Float>,
                   _ v1: SIMD3<Float>,
                   _ v2: SIMD3<Float>) -> SIMD4<Float> {

        let v10 = v1-v0
        let v20 = v2-v0
        let n = simd_cross(v10,v20)
        return SIMD4<Float>(n.x, n.y, n.z, 0)
    }
}
