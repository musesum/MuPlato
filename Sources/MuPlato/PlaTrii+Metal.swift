//  Created by warren on 2/22/23.
//  Copyright © 2023 com.deepmuse. All rights reserved.

import Foundation
import Metal
import Vision
import UIKit

extension PlaTrii {

    func updateBuffers(_ device: MTLDevice,
                       _ counter: PlatoCounter,
                       _ platonic: Platonic) {

        let platoOps = platonic.platoOps
        let vertexCount = tri01s.count*3
        let indexCount = tri01s.count*3

        var vertices = [Vert01](repeating: Vert01(), count: vertexCount)
        var indices =  [UInt32](repeating:        0, count: indexCount)
        var vi = 0

        
        if PlaTrii.logVertex { print() }

        for tri in tri01s {

            //let faceId = TriId.id(tri, counter.phase, counter.increasing)

            // n0...n1 triangle face normals in ranged 0...1
            let n0 = simd_cross((tri.v1.p0 - tri.v0.p0),
                                (tri.v2.p0 - tri.v0.p0))

            let n1 = simd_cross((tri.v1.p1 - tri.v0.p1),
                                (tri.v2.p1 - tri.v0.p1))

            for p in [tri.v0, tri.v1, tri.v2] {

                vertices[vi].p0 = pnt4f(p.p0, 1)
                vertices[vi].n0 = pnt4f(  n0, 0)
                vertices[vi].p1 = pnt4f(p.p1, 1)
                vertices[vi].n1 = pnt4f(  n1, 0)
                vertices[vi].extra.x = Float(p.id) // vertId
                vertices[vi].extra.y = Float(tri.id) // faceId
                vertices[vi].extra.z = Float(p.h) // harmonic

                if !platoOps.colorizeTri ||
                    platoOps.reflectCube {
                    let shade =  0.33333 + Float(p.h) / 3 * 0.5
                    let grey = platoOps.invertShade ? 1 - shade : shade
                    vertices[vi].color = Pnt4(grey, grey, grey, 1)
                } else {
                    vertices[vi].color = colorForId(tri.id, p.h, platonic)
                }
                indices[vi] = UInt32(vi)
                if PlaTrii.logVertex {
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

    func colorForId(_ id: Int,
                    _ harmonic: Int,
                    _ platonic: Platonic) -> Pnt4 {

        let platoOps = platonic.platoOps
        let grey = 0.33333 + (platoOps.colorShade ? Float(harmonic) / 3 * 0.5 : 0)

        
        let colorHue = CGFloat((id * platonic.colorStride) % platonic.colorCount ) / CGFloat(platonic.colorCount)
        let cg = UIColor(hue: colorHue,
                         saturation: 1,
                         brightness: 1,
                         alpha: 1).cgColor

        let ci = CIColor(cgColor: cg)
        return Pnt4( (2 * Float(ci.red  ) - grey) / 2,
                     (2 * Float(ci.green) - grey) / 2,
                     (2 * Float(ci.blue ) - grey) / 2,
                     1)

    }
}
