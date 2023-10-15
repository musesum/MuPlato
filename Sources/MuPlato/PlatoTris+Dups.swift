//  Created by warren on 5/5/23.

import Foundation
import Metal
import Vision
import UIKit
import simd



extension SIMD4 {
    var xyz: SIMD3<Scalar> {
        SIMD3(x, y, z)
    }
}

extension SIMD3<Float> {
    func hash(_ max: Float) -> Scalar {
        let h = ((x+max) * max * max) + ((y+max) * max) + (z + max)
        return h
    }
    var script: String {
        "(\(x.digits(0...2)),\(y.digits(0...2)),\(z.digits(0...2)))".pad(18)
    }
}

var faceHashP0 = Set<Float>()
var faceHashP1 = Set<Float>()

extension PlatoTris {

    func updateBuffersDups(_ device: MTLDevice) {

        let vertexCount = tri01s.count*3
        let indexCount = tri01s.count*3

        var vertices = [PlatoVertex](repeating: PlatoVertex(), count: vertexCount)
        var indices =  [UInt32](repeating:        0, count: indexCount)
        var vi = 0

        if PlatoTris.logVertex { print() }

            faceHashP0.removeAll(keepingCapacity: true)
        faceHashP1.removeAll(keepingCapacity: true)


        for tri in tri01s {

            if testDuplicate("p0", tri.v0.p0, tri.v1.p0, tri.v2.p0, tri) {
                continue
            }

            for v in [tri.v0, tri.v1, tri.v2] {
                let convex = pow(PlatoFlo.shared.harmonif,Float(v.h))
                vertices[vi].pos0 = pnt4f(v.p0, 1) * convex
                vertices[vi].pos1 = pnt4f(v.p1, 1) * convex
                vertices[vi].vertId = Float(v.id)
                vertices[vi].faceId = Float(tri.id)
                vertices[vi].harmonic = Float(v.h)

                indices[vi] = UInt32(vi)
                if PlatoTris.logVertex {
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

    func testDuplicate(_ from: String,
                       _ v0: SIMD3<Float>,
                       _ v1: SIMD3<Float>,
                       _ v2: SIMD3<Float>,
                       _ tri: Tri01) -> Bool {
        let combined = v0.hash(10) * v1.hash(10) * v2.hash(10)

        if from == "p0" {

            if faceHashP0.contains(combined)  {
                printDup()
                return true
            } else {
                faceHashP0.insert(combined)
                return false
            }
        }  else if from == "p1" {
            if faceHashP1.contains(combined)  {
                printDup()
                return true
            } else {
                faceHashP0.insert(combined)
                return false
            }
        } else {
            print("testDuplicate unknown from \(from)")
            return false
        }
        func printDup() {

            let cross = cross(v0, v1)
            let area = length(cross)
            let v10 = v1-v0
            let v20 = v2-v0
            let norm = simd_cross(v10,v20)

            print("*** duplcate \(from): \(v0.script),\(v1.script),\(v2.script) harmonic:(\(tri.v0.h),\(tri.v1.h),\(tri.v2.h)) normal: \(norm.script) area: \(area)")

        }
    }
}
