//  created by musesum on 2/15/23.

import Foundation
import Metal
import MetalKit
import MuVision

class PlatoModel: MeshModel {

    static var logVertex = false

    var tri01s: [Tri01]

    init(_ device: MTLDevice,
         _ metalVD: MTLVertexDescriptor,
         _ tris: [Tri01]) {

        self.tri01s = tris
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
                 _ superTris: [Tri01]? = nil) -> [Tri01] {

        let superTris = superTris ?? tri01s
        if depth == harmonic {
            return superTris
        }
        var subTris = [Tri01]()

        for tri in superTris {

            let c0 = tri.centroid(0) // middle of lowerbound 0...1
            let c1 = tri.centroid(1) // middle of upperbound 0...1
            let c01 = Vertex01(c0, c1, harmonic: depth+1) // used to calc concave/convex relative to (0,0,0)

            subTris.append( Tri01(tri.v0, tri.v1, c01))
            subTris.append( Tri01(tri.v1, tri.v2, c01))
            subTris.append( Tri01(tri.v2, tri.v0, c01))
        }
        tri01s = trisect(harmonic, depth+1, subTris)
        return tri01s
    }


}
