//  created by musesum on 2/15/23.

import Foundation
import Metal
import MetalKit
import MuVision

class PlatoModel: MeshModel {

    static var logVertex = false

    var triRanges: [TriRange]

    init(_ device: MTLDevice,
         _ metalVD: MTLVertexDescriptor,
         _ triRanges: [TriRange]) {

        self.triRanges = triRanges
        super.init(device,metalVD)
    }

    func pnt4f(_ p: Float3,_ w: Float) -> Pnt4 {
        return Pnt4(Float(p.x),
                    Float(p.y),
                    Float(p.z),
                    w)
    }
    /// subdivide each Tri01 into 3 Tri01(s) until 3^harmonic divisions
    func trisect(_ harmonic: Int,
                 _ depth: Int = 0,
                 _ superTris: [TriRange]? = nil) -> [TriRange] {

        let superTris = superTris ?? triRanges
        if depth == harmonic {
            return superTris
        }
        var subTris = [TriRange]()

        for tri in superTris {

            let c0 = tri.centroid(0) // middle of lowerbound 0...1
            let c1 = tri.centroid(1) // middle of upperbound 0...1
            let c01 = VertexRange(c0, c1, harmonic: depth+1) // used to calc concave/convex relative to (0,0,0)

            subTris.append(TriRange(tri.v0, tri.v1, c01))
            subTris.append(TriRange(tri.v1, tri.v2, c01))
            subTris.append(TriRange(tri.v2, tri.v0, c01))
        }
        triRanges = trisect(harmonic, depth+1, subTris)
        return triRanges
    }


}
