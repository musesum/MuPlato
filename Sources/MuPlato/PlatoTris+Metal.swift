//  Created by warren on 2/22/23.
//  Copyright © 2023 com.deepmuse. All rights reserved.

import Foundation
import Metal
import Vision
import UIKit

extension PlatoTris {

    func updateBuffers(_ device: MTLDevice,
                       _ counter: PlatoCounter,
                       _ platonic: Platonic) {

        let vertexCount = tri01s.count*3
        let indexCount = tri01s.count*3

        var vertices = [Vert01](repeating: Vert01(), count: vertexCount)
        var indices =  [UInt32](repeating:        0, count: indexCount)
        var vi = 0
        
        if PlatoTris.logVertex { print() }

        for tri in tri01s {

            //let faceId = TriId.id(tri, counter.phase, counter.increasing)b

            for p in [tri.v0, tri.v1, tri.v2] {

                vertices[vi].p0 = pnt4f(p.p0, 1)
                vertices[vi].p1 = pnt4f(p.p1, 1)
                vertices[vi].extra.x = Float(p.id)   // vertId
                vertices[vi].extra.y = Float(tri.id) // faceId
                vertices[vi].extra.z = Float(p.h)    // harmonic

                indices[vi] = UInt32(vi)
                if PlatoTris.logVertex {
                    logVert01(vertices[vi], vi)
                }
                vi += 1
            }
        }
        let verticesLen = MemoryLayout<Vert01>.size * vertexCount
        let indicesLen = MemoryLayout<UInt32>.size * indexCount
        vertexBuf = device.makeBuffer(bytes: vertices, length: verticesLen)
        indexBuf  = device.makeBuffer(bytes: indices , length: indicesLen)
    }

}
