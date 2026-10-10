import XCTest
import simd
@testable import MuPlato

/// the welded vertex normals of the rigid solids: the phases that meet at a
/// boundary agree there, the sums take the triangles with area before the
/// convex pull, and hasArea's cutoff sits inside the measured gap
final class PlatoNormalTests: XCTestCase {

    /// PlatoModel.buildHarmonic + buildPhase for the rigid solids
    func buildPhases(harmonic: Int, convex: Float, blend: Float) -> [PhaseTriangles] {
        TriRange.reset()
        var phases = [PhaseTriangles]()
        for phase in 0 ..< 11 { phases.append(PhaseTriangles.build(phase)) }
        for phase in phases { _ = phase.trisect(harmonic) }
        for (i, phase) in phases.enumerated() { for tri in phase.triRanges { tri.setId(i) } }
        for (i, phase) in phases.enumerated() { phase.updateTriangles(convex, i, smooth: blend) }
        return phases
    }

    func degrees(_ a: SIMD3<Float>, _ b: SIMD3<Float>) -> Float {
        let la = simd_length(a), lb = simd_length(b)
        guard la > 1e-9, lb > 1e-9 else { return 0 }
        return acos(max(-1, min(1, simd_dot(a / la, b / lb)))) * 180 / .pi
    }

    /// a triangle's corners before the pull (TriRange) and as built (vertices)
    func corners(_ ph: PhaseTriangles, _ t: Int, end: Int) -> (table: [SIMD3<Float>], built: [SIMD4<Float>]) {
        let tri = ph.triRanges[t]
        let table = end == 0 ? [tri.v0.p0, tri.v1.p0, tri.v2.p0] : [tri.v0.p1, tri.v1.p1, tri.v2.p1]
        let built = (0 ..< 3).map { end == 0 ? ph.vertices[t * 3 + $0].pos0 : ph.vertices[t * 3 + $0].pos1 }
        return (table, built)
    }

    /// twice the area the table corners span at that end
    func span(_ table: [SIMD3<Float>]) -> Float {
        simd_length(simd_cross(table[1] - table[0], table[2] - table[0]))
    }

    /// the built normals: the area-weighted sum of outward face normals over
    /// the triangles with area before the pull at the welded position, else
    /// the radial direction. the oracle draws its line at 1e-6 (testHasAreaGap
    /// shows 1e-6…1e-4 empty); positions off the radial direction show that
    /// the sums, not the fallback, are being read
    func testNormalsFollowTheTrianglesWithArea() {
        for harmonic in [2, 3, 6] {
            let phases = buildPhases(harmonic: harmonic, convex: 0.98, blend: 1)
            for (p, ph) in phases.enumerated() {
                for end in 0 ... 1 {
                    var sum = [String: SIMD3<Float>]()
                    for t in ph.triRanges.indices {
                        let (table, built) = corners(ph, t, end: end)
                        guard span(table) > 1e-6 else { continue }
                        let (a, b, c) = (built[0].xyz, built[1].xyz, built[2].xyz)
                        var n = simd_cross(b - a, c - a)
                        if simd_dot(n, a + b + c) < 0 { n = -n }
                        for k in built { sum[PlatoSprings.weldKey(k), default: .zero] += n }
                    }
                    var worst = Float(0), offRadial = 0
                    for v in ph.vertices {
                        let pos = end == 0 ? v.pos0 : v.pos1
                        let norm = end == 0 ? v.norm0 : v.norm1
                        let s = sum[PlatoSprings.weldKey(pos)] ?? .zero
                        let expect = simd_length(s) > 1e-9 ? s : pos.xyz
                        guard simd_length(expect) > 1e-9 else { continue }
                        worst = max(worst, degrees(norm.xyz, expect))
                        if degrees(expect, pos.xyz) > 1 { offRadial += 1 }
                        XCTAssertEqual(norm.w, 1, "blend carried in w")
                    }
                    let tag = "phase \(p) end \(end) harmonic \(harmonic)"
                    XCTAssertLessThan(worst, 0.1, "\(tag): a normal is \(worst)° off the sum")
                    if p > 0 || end > 0 {
                        XCTAssertGreaterThan(offRadial, 0, "\(tag): every normal is radial")
                    }
                }
            }
        }
    }

    /// phase p at range01 1 and phase p+1 at range01 0 describe one solid: the
    /// shader lerps norm0 → norm1 within a phase, so the two must agree at
    /// every shared position
    func testVertexNormalsAgreeAcrossEveryPhaseBoundary() {
        for convex in [Float(0.9), 0.98, 1.1] {
            for harmonic in 0 ... 3 {
                let phases = buildPhases(harmonic: harmonic, convex: convex, blend: 1)
                for p in 0 ..< 10 {
                    var end = [String: SIMD3<Float>](), start = [String: SIMD3<Float>]()
                    for v in phases[p].vertices { end[PlatoSprings.weldKey(v.pos1)] = v.norm1.xyz }
                    for v in phases[p + 1].vertices { start[PlatoSprings.weldKey(v.pos0)] = v.norm0.xyz }
                    var worst = Float(0), shared = 0
                    for (key, n1) in end {
                        guard let n0 = start[key] else { continue }
                        shared += 1
                        worst = max(worst, degrees(n1, n0))
                    }
                    let tag = "phase \(p)→\(p+1) harmonic \(harmonic) convex \(convex)"
                    XCTAssertGreaterThan(shared, 0, "\(tag): no shared position")
                    XCTAssertLessThan(worst, 0.1, "\(tag): normals jump \(worst)°")
                }
            }
        }
    }

    /// the triangles with area at the end of phase p are, one for one, the
    /// triangles with area at the start of phase p+1; only slivers differ
    func testTrianglesWithAreaMatchAcrossEveryPhaseBoundary() {
        for harmonic in [0, 3] {
            let phases = buildPhases(harmonic: harmonic, convex: 0.98, blend: 1)
            func keyed(_ ph: PhaseTriangles, end: Int) -> [String: Int] {
                var found = [String: Int]()
                for t in ph.triRanges.indices {
                    let (table, built) = corners(ph, t, end: end)
                    guard span(table) > 1e-6 else { continue }
                    found[built.map { PlatoSprings.weldKey($0) }.sorted().joined(separator: "|"), default: 0] += 1
                }
                return found
            }
            for p in 0 ..< 10 {
                let end = keyed(phases[p], end: 1), start = keyed(phases[p + 1], end: 0)
                XCTAssertGreaterThan(end.count, 0, "phase \(p) has no triangle with area at its end")
                XCTAssertEqual(end, start, "phase \(p)→\(p+1) harmonic \(harmonic): triangles with area differ")
            }
        }
    }

    /// no triangle spans between 1e-6 and 1e-4 before the pull at any
    /// harmonic, and hasArea splits the two sides that gap leaves
    func testHasAreaGap() {
        for harmonic in 0 ... 6 {
            let phases = buildPhases(harmonic: harmonic, convex: 0.98, blend: 0)
            var withArea = 0, without = 0
            for ph in phases {
                for t in ph.triRanges.indices {
                    for end in 0 ... 1 {
                        let table = corners(ph, t, end: end).table
                        let twice = span(table)
                        XCTAssertFalse(twice > 1e-6 && twice <= 1e-4, "harmonic \(harmonic): a span of \(twice) sits in the gap")
                        let has = ph.hasArea(table[0], table[1], table[2])
                        XCTAssertEqual(has, twice > 1e-4, "harmonic \(harmonic): hasArea \(has) at span \(twice)")
                        if has { withArea += 1 } else { without += 1 }
                    }
                }
            }
            XCTAssertGreaterThan(withArea, 0)
            XCTAssertGreaterThan(without, 0)
        }
    }
}
