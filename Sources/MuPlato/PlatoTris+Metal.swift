//  Created by warren on 2/22/23.
//  Copyright © 2023 com.deepmuse. All rights reserved.

import Foundation
import Metal
import Vision
import UIKit
import simd



extension PlatoTris {

    func updateBuffers(_ device: MTLDevice) {

        let vertexCount = tri01s.count*3
        let indexCount = tri01s.count*3

        var vertices = [Vert01](repeating: Vert01(), count: vertexCount)
        var indices =  [UInt32](repeating:        0, count: indexCount)
        var vi = 0
        
        if PlatoTris.logVertex { print() }

        for tri in tri01s {

            for v in [tri.v0, tri.v1, tri.v2] {

                let harmonic = Float(v.h)
                let convex = pow(PlatoFlo.shared.harmonif,harmonic)
                vertices[vi].p0 = pnt4f(v.p0, 1) * convex
                vertices[vi].p1 = pnt4f(v.p1, 1) * convex
                vertices[vi].extra.x = Float(v.id)   // vertId
                vertices[vi].extra.y = Float(tri.id)  // faceId
                vertices[vi].extra.z = Float(v.h)    // harmonic

                indices[vi] = UInt32(vi)
                if PlatoTris.logVertex {
                    logVert01(vertices[vi], vi)
                }
                vi += 1
            }

            let n0 = normalize(vertices[vi-3].p0.xyz,
                               vertices[vi-2].p0.xyz,
                               vertices[vi-1].p0.xyz)
            vertices[vi-3].n0 = n0
            vertices[vi-2].n0 = n0
            vertices[vi-1].n0 = n0

            let n1 = normalize(vertices[vi-3].p1.xyz,
                               vertices[vi-2].p1.xyz,
                               vertices[vi-1].p1.xyz)
            vertices[vi-3].n1 = n1
            vertices[vi-2].n1 = n1
            vertices[vi-1].n1 = n1
        }
        let verticesLen = MemoryLayout<Vert01>.size * vertexCount
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
