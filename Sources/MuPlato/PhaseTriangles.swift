//  created by musesum on 2/15/23.

import Foundation
import Metal
import MetalKit
import MuFlo
import simd

class PhaseTriangles {

    nonisolated(unsafe) static var logVertex = false

    var triRanges: [TriRange]
    var triCount: Int { return triRanges.count * 3 }
    var vertices: [PlatoVertex]!
    var indices: [UInt32]!

    init(_ triRanges: [TriRange]) {

        self.triRanges = triRanges
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

    /// WinSky Shape::subdivide: each Tri01 into 4 by its edge midpoints,
    /// 4^harmonic divisions; every interior vertex keeps valence 6 as the
    /// icosahedral mesh the spring constants were tuned on. a flat midpoint
    /// sits inside the corner sphere, so the ball comes out spiky: each
    /// midpoint is pushed back out to its parents' mean radius, the classic
    /// icosphere, and the springs then rest on a round shape
    func quadsect(_ harmonic: Int,
                  _ depth: Int = 0,
                  _ superTris: [TriRange]? = nil) -> [TriRange] {

        let superTris = superTris ?? triRanges
        if depth == harmonic {
            return superTris
        }
        var subTris = [TriRange]()

        for tri in superTris {

            let m01 = VertexRange(PhaseTriangles.geodesic(tri.v0.p0, tri.v1.p0),
                                  PhaseTriangles.geodesic(tri.v0.p1, tri.v1.p1), harmonic: depth+1)
            let m12 = VertexRange(PhaseTriangles.geodesic(tri.v1.p0, tri.v2.p0),
                                  PhaseTriangles.geodesic(tri.v1.p1, tri.v2.p1), harmonic: depth+1)
            let m20 = VertexRange(PhaseTriangles.geodesic(tri.v2.p0, tri.v0.p0),
                                  PhaseTriangles.geodesic(tri.v2.p1, tri.v0.p1), harmonic: depth+1)

            subTris.append(TriRange(m01, m12, m20))
            subTris.append(TriRange(tri.v0, m01, m20))
            subTris.append(TriRange(tri.v1, m12, m01))
            subTris.append(TriRange(tri.v2, m20, m12))
        }
        triRanges = quadsect(harmonic, depth+1, subTris)
        return triRanges
    }

    /// midpoint of a and b lifted to their mean radius; the same arithmetic
    /// for either order, so the weld by position still joins shared edges.
    /// a midpoint at the origin (phase 0 grows from a point) has no
    /// direction and stays put
    static func geodesic(_ a: Float3, _ b: Float3) -> Float3 {
        let m = VertexRange.mid2(a, b)
        let len = simd_length(m)
        guard len > 1e-6 else { return m }
        return m * ((simd_length(a) + simd_length(b)) / 2 / len)
    }

    /// project every corner onto its phase end's circumsphere, the largest
    /// corner radius at that end, so the seeds a morph grows from a face
    /// centre or an edge midpoint no longer dent the ball; ids and
    /// harmonics survive, so face ids and shading read as before. a corner
    /// at the origin stays put. call before quadsect, which keeps the
    /// subdivisions on that sphere
    func spherize() {
        var radius0 = Float(0), radius1 = Float(0)
        for tri in triRanges {
            for v in [tri.v0, tri.v1, tri.v2] {
                radius0 = max(radius0, simd_length(v.p0))
                radius1 = max(radius1, simd_length(v.p1))
            }
        }
        func liftPoint(_ p: Float3, _ radius: Float) -> Float3 {
            let len = simd_length(p)
            return len > 1e-6 ? p * (radius / len) : p
        }
        func liftVertex(_ v: VertexRange) -> VertexRange {
            var lifted = VertexRange(liftPoint(v.p0, radius0), liftPoint(v.p1, radius1), v.id)
            lifted.harmonic = v.harmonic
            return lifted
        }
        triRanges = triRanges.map { TriRange(liftVertex($0.v0), liftVertex($0.v1), liftVertex($0.v2)) }
    }


}
