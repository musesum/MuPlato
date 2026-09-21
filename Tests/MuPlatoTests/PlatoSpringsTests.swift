// created by musesum on 9/16/26

import XCTest
import simd
@testable import MuPlato

/// the ico ball: round at rest, stable under the classic balloon pressure,
/// and a touch impulse that rings down. iOS-only package: run through Xcode
final class PlatoSpringsTests: XCTestCase {

    /// ico build at a middle harmonic, as PlatoModel.buildHarmonic does it
    func makeBall(phase: Int, harmonic: Int, smooth: Float = 0) -> PhaseTriangles {
        let tris = PhaseTriangles.build(phase)
        tris.spherize()
        _ = tris.quadsect(harmonic)
        tris.updateTriangles(1, phase, smooth: smooth) // ico ignores convex
        return tris
    }

    func radii(_ points: [SIMD3<Float>]) -> (mean: Float, min: Float, max: Float) {
        var sum = Float(0), lo = Float.greatestFiniteMagnitude, hi = Float(0)
        for p in points {
            let l = simd_length(p)
            sum += l; lo = min(lo, l); hi = max(hi, l)
        }
        return (sum / Float(max(1, points.count)), lo, hi)
    }

    /// every vertex of every phase end sits on that end's circumsphere:
    /// no corner spikes, no midpoint dents. phase 0 grows from the origin,
    /// so its start is the one end allowed at radius 0
    func testIcoMeshIsRound() {
        for phase in 0 ..< 11 {
            let tris = makeBall(phase: phase, harmonic: 3)
            for end in 0 ... 1 {
                let points = tris.vertices.map { end == 0 ? $0.pos0.xyz : $0.pos1.xyz }
                let r = radii(points.filter { simd_length($0) > 1e-6 })
                if r.max == 0 { XCTAssertEqual(phase, 0); continue }
                XCTAssertLessThan(r.max - r.min, 1e-3 * r.max,
                                  "phase \(phase) end \(end) radius \(r.min)…\(r.max)")
            }
        }
    }

    /// 600 frames at balloon 0.67 with one touch at frame 50: finite, the
    /// mean radius within 0.85…1.5 of rest, quieter at 600 than at 60
    func testIcoBallRingsDown() {
        let tris = makeBall(phase: 10, harmonic: 3) // dodec → icosa, held at the dodec end
        let vertices = tris.vertices!
        let rest = radii(vertices.map { $0.pos0.xyz }).mean
        let springs = PlatoSprings(vertices)
        var energy60 = Float(0)

        for frame in 0 ..< 600 {
            if frame == 50 { springs.impulse(at: vertices[0].pos0.xyz) }
            springs.step(balloon: 0.67, range01: 0)
            XCTAssertTrue(springs.energy.isFinite, "frame \(frame) energy not finite")
            let r = radii(vertices.indices.map { springs.position($0) })
            XCTAssertTrue(r.mean.isFinite, "frame \(frame) radius not finite")
            XCTAssertGreaterThanOrEqual(r.mean, rest * 0.85, "frame \(frame) collapsed to \(r.mean / rest)")
            XCTAssertLessThanOrEqual(r.mean, rest * 1.5, "frame \(frame) blew up to \(r.mean / rest)")
            if frame == 60 { energy60 = springs.energy }
        }
        XCTAssertGreaterThan(energy60, 0, "the touch left no energy to ring down")
        XCTAssertLessThan(springs.energy, energy60, "still ringing: \(springs.energy) ≥ \(energy60)")
    }

    /// the swollen ball rests on the built sphere whether touched or not
    /// (plato.material w 'normal' 1 shows the vertex normals): once a touch
    /// rings down, every vertex sits at `inflate` times its built position
    /// and its normal is the built one, as a fresh build shows it. the
    /// untrimmed push rested these meshes 1…22% out of round
    func testTouchedBallRestsOnBuiltSphere() {
        for (phase, harmonic) in [(10, 3), (4, 2), (8, 2), (5, 3)] {
            let tris = makeBall(phase: phase, harmonic: harmonic, smooth: 1)
            let vertices = tris.vertices!
            let springs = PlatoSprings(vertices)
            for frame in 0 ..< 4000 {
                if frame == 50 { springs.impulse(at: vertices[0].pos0.xyz) }
                springs.step(balloon: 0.67, range01: 0)
            }
            let tag = "phase \(phase) harmonic \(harmonic)"
            XCTAssertGreaterThan(springs.inflate, 1.01, tag)
            XCTAssertLessThan(springs.inflate, 1.15, tag)
            XCTAssertLessThan(springs.energy, 1e-6, tag)
            var worstPos = Float(0), worstAngle = Float(0)
            for i in vertices.indices {
                let built = vertices[i].pos0.xyz
                let rest = built * springs.inflate
                worstPos = max(worstPos, simd_length(springs.position(i) - rest) / simd_length(rest))
                let cosine = simd_dot(springs.vertexNormal(i), simd_normalize(vertices[i].norm0.xyz))
                worstAngle = max(worstAngle, acos(min(1, cosine)) * 180 / .pi)
            }
            XCTAssertLessThan(worstPos, 1e-4, "\(tag): a vertex rests \(worstPos) off the sphere")
            XCTAssertLessThan(worstAngle, 0.1, "\(tag): a normal rests \(worstAngle)° off the built one")
        }
    }

    /// new springs start at their rest: the first step shows the round
    /// ball at its swollen size, with no lumpy swell into it
    func testFirstStepIsRound() {
        let tris = makeBall(phase: 10, harmonic: 3)
        let vertices = tris.vertices!
        let springs = PlatoSprings(vertices)
        springs.step(balloon: 0.67, range01: 0)
        for i in vertices.indices {
            let rest = vertices[i].pos0.xyz * springs.inflate
            XCTAssertLessThan(simd_length(springs.position(i) - rest), 1e-4)
        }
    }

    /// springs rebuilt on a fresh mesh start still: no offset survives a
    /// rebuild, so an ico off → on cycle rests on the built vertices
    func testFreshSpringsRestOnMesh() {
        let tris = makeBall(phase: 4, harmonic: 2)
        let springs = PlatoSprings(tris.vertices)
        for i in tris.vertices.indices {
            XCTAssertEqual(simd_length(springs.offset(i)), 0)
        }
        XCTAssertFalse(springs.active)
    }
}
