//  created by musesum on 2/22/23.

import Foundation
import Metal
import Vision
import UIKit
import simd

extension PlatoModel {

    func updateBuffers(_ device: MTLDevice) {

        let vertexCount = triRanges.count*3
        let indexCount = triRanges.count*3

        var vertices = [PlatoVertex](repeating: PlatoVertex(), count: vertexCount)
        var indices =  [UInt32]     (repeating:             0, count: indexCount)
        var vi = 0
        
        if PlatoModel.logVertex { print() }

        for tri in triRanges {

            for vert in [tri.v0, tri.v1, tri.v2] {

                let harmonic = Float(vert.h)
                let convex = pow(PlatoFlo.shared.harmonif,harmonic)
                vertices[vi].pos0 = pnt4f(vert.p0, 1) * convex
                vertices[vi].pos1 = pnt4f(vert.p1, 1) * convex
                vertices[vi].vertId = Float(vert.id)   
                vertices[vi].faceId = Float(tri.id)
                vertices[vi].harmonic = Float(vert.h)

                indices[vi] = UInt32(vi)
                if PlatoModel.logVertex {
                    logVert01(vertices[vi], vi)
                }
                vi += 1
            }

            let n0 = normalize(vertices[vi-3].pos0.xyz,
                               vertices[vi-2].pos0.xyz,
                               vertices[vi-1].pos0.xyz)
            vertices[vi-3].norm0 = n0
            vertices[vi-2].norm0 = n0
            vertices[vi-1].norm0 = n0

            let n1 = normalize(vertices[vi-3].pos1.xyz,
                               vertices[vi-2].pos1.xyz,
                               vertices[vi-1].pos1.xyz)
            vertices[vi-3].norm1 = n1
            vertices[vi-2].norm1 = n1
            vertices[vi-1].norm1 = n1
        }
        let verticesLen = MemoryLayout<PlatoVertex>.size * vertexCount
        let indicesLen = MemoryLayout<UInt32>.size * indexCount
        vertexBuf = device.makeBuffer(bytes: vertices, length: verticesLen)
        indexBuf  = device.makeBuffer(bytes: indices , length: indicesLen)
    }
    func normalize(_ v0: SIMD3<Float>,
                   _ v1: SIMD3<Float>,
                   _ v2: SIMD3<Float>) -> SIMD4<Float> {

        let v10 = v1-v0
        let v20 = v2-v0
        let n = simd_cross(v10,v20)
        return SIMD4<Float>(n.x, n.y, n.z, 0)
    }

    func updateHarmonif(_ harmonif: Float, _ device: MTLDevice) {
        updateBuffers(device)
    }
}
