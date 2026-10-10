// created by musesum on 9/29/26

import XCTest
import simd
@testable import MuPlato

/// a held touch on a platonic solid while the clock is off: no balloon, a
/// stronger home pull (HomePull.solid), each slot sunk at most ownShare of
/// its own radius, the press aimed where the sight ray meets the faces. The
/// numbers were measured on these meshes with an optimised build of the
/// same arithmetic before the change landed
extension PlatoSpringsTests { // + Solid

    /// a platonic phase as the clock leaves it: trisected, pulled to the
    /// phase's convex
    func makeSolid(phase: Int, harmonic: Int) -> [PlatoVertex] {
        let tris = PhaseTriangles.build(phase)
        _ = tris.trisect(harmonic)
        tris.updateTriangles(0.98, phase)
        return tris.vertices
    }
    /// springs welded and sized where the clock stopped, stepped once there
    func solidSprings(_ vertices: [PlatoVertex], range01: Float,
                      pull: Float = PlatoSprings.HomePull.solid) -> PlatoSprings {
        let springs = PlatoSprings(vertices, homePull: pull, solid: true, at: range01)
        springs.step(balloon: 0, range01: range01)
        return springs
    }
    /// the lowest slot as a share of its own rest radius, the farthest any
    /// slot stands off its rest and the deepest dent, ball radii; rest is
    /// where the springs hold each slot at the frozen morph
    func solidStats(_ springs: PlatoSprings, _ vertices: [PlatoVertex]) -> (low: Float, off: Float, dent: Float) {
        var low = Float(9), off = Float(0), dent = Float(0)
        let R = springs.restRadius
        for i in vertices.indices {
            let d = springs.offset(i)
            let rest = springs.position(i) - d
            let rr = simd_length(rest)
            guard rr > 1e-6 else { continue }
            let r = simd_dot(springs.position(i), rest / rr)
            low = min(low, r / rr)
            off = max(off, simd_length(d) / R)
            dent = max(dent, (rr - r) / R)
        }
        return (low, off, dent)
    }
    /// the rest direction of the first triangle's first corner or its centre
    func solidDir(_ v: [PlatoVertex], _ range01: Float, face: Bool) -> SIMD3<Float> {
        func at(_ i: Int) -> SIMD3<Float> { v[i].pos0.xyz + (v[i].pos1.xyz - v[i].pos0.xyz) * range01 }
        return simd_normalize(face ? at(0) + at(1) + at(2) : at(0))
    }

    /// untouched, the solid's springs hold it exactly as built, mid-morph too
    func testSolidRestsStill() {
        for (phase, harmonic) in [(1, 2), (4, 1), (8, 2), (10, 2)] {
            for range01 in [Float(0), 0.5, 1] {
                let vertices = makeSolid(phase: phase, harmonic: harmonic)
                let springs = solidSprings(vertices, range01: range01)
                for _ in 0 ..< 120 { springs.step(balloon: 0, range01: range01) }
                let tag = "phase \(phase) harmonic \(harmonic) range01 \(range01)"
                XCTAssertLessThan(solidStats(springs, vertices).off, 1e-5, tag)
                XCTAssertFalse(springs.active, tag)
            }
        }
    }

    /// the deepest press, at a corner or a face centre, mid-morph or not,
    /// never pushes a slot through the centre and always comes home. At the
    /// ball's pull a pressed patch of phase 4 snaps through and stays
    func testSolidPressComesHome() {
        for (phase, harmonic) in [(1, 2), (4, 0), (4, 3), (7, 0), (10, 1)] {
            for range01 in [Float(0), 0.5] {
                for face in [false, true] {
                    let vertices = makeSolid(phase: phase, harmonic: harmonic)
                    let springs = solidSprings(vertices, range01: range01)
                    let press = SpringPress(id: 1, dir: solidDir(vertices, range01, face: face),
                                            pressure: 1, foot: 0.2 * springs.restRadius)
                    var low = Float(9)
                    for frame in 0 ..< 1020 {
                        springs.step(balloon: 0, range01: range01,
                                     presses: frame < 120 ? [press] : [], pressDepth: PlatoSprings.depthMax)
                        low = min(low, solidStats(springs, vertices).low)
                    }
                    let tag = "phase \(phase) harmonic \(harmonic) range01 \(range01) face \(face)"
                    XCTAssertTrue(springs.energy.isFinite, tag)
                    XCTAssertGreaterThan(low, -0.05, "\(tag): a slot fell through the centre to \(low)")
                    // still ringing down at the drag's 1% a step (0.6% of R at
                    // most), where a fold stands 4.5% of R off or more
                    XCTAssertLessThan(solidStats(springs, vertices).off, 0.02, "\(tag): folded")
                }
            }
        }
        let vertices = makeSolid(phase: 4, harmonic: 0)
        let springs = solidSprings(vertices, range01: 0.5, pull: PlatoSprings.HomePull.ball)
        let press = SpringPress(id: 1, dir: solidDir(vertices, 0.5, face: false),
                                pressure: 1, foot: 0.2 * springs.restRadius)
        for frame in 0 ..< 1020 {
            springs.step(balloon: 0, range01: 0.5, presses: frame < 120 ? [press] : [], pressDepth: 0.5)
        }
        XCTAssertGreaterThan(solidStats(springs, vertices).off, 0.1, "the ball's pull leaves it folded")
    }

    /// a light fingertip dents a solid to its pressure and no deeper
    func testSolidLightTouchOnlyPresses() {
        for (phase, harmonic) in [(1, 1), (5, 2), (8, 1), (10, 2)] {
            for face in [false, true] {
                let vertices = makeSolid(phase: phase, harmonic: harmonic)
                let springs = solidSprings(vertices, range01: 0)
                let press = SpringPress(id: 1, dir: solidDir(vertices, 0, face: face),
                                        pressure: 0.25, foot: 0.2 * springs.restRadius)
                var peak = Float(0)
                for _ in 0 ..< 60 {
                    springs.step(balloon: 0, range01: 0, presses: [press], pressDepth: 0.5)
                    peak = max(peak, solidStats(springs, vertices).dent)
                }
                XCTAssertLessThanOrEqual(peak, 1.1 * 0.25 * 0.5, "phase \(phase) face \(face): peak \(peak)")
            }
        }
    }

    /// a solid is no sphere: a sight ray that meets a face off the view
    /// axis meets the ball's sphere far from it, so the press aims at the
    /// faces themselves
    func testSolidAimsAtItsFaces() throws {
        let vertices = makeSolid(phase: 1, harmonic: 0)
        let springs = solidSprings(vertices, range01: 0)
        func at(_ i: Int) -> SIMD3<Float> { vertices[i].pos0.xyz }
        // the face whose centre leans most toward +z, seen from 40° off its axis
        var best = 0
        for t in stride(from: 0, to: vertices.count - 2, by: 3)
        where simd_normalize(at(t) + at(t+1) + at(t+2)).z > simd_normalize(at(best) + at(best+1) + at(best+2)).z {
            best = t
        }
        let centre = (at(best) + at(best+1) + at(best+2)) / 3
        let axis = simd_normalize(centre)
        let side = simd_normalize(simd_cross(axis, abs(axis.x) < 0.9 ? SIMD3<Float>(1, 0, 0) : SIMD3<Float>(0, 1, 0)))
        let a = Float.pi * 40 / 180
        let eye = centre + (axis * cos(a) + side * sin(a)) * 4 * springs.restRadius
        let ray = simd_normalize(centre - eye)
        let hit = try XCTUnwrap(PlatoNode.nearestHit(eye, ray, vertices.count, at))
        XCTAssertLessThan(simd_distance(hit, centre), 1e-4 * springs.restRadius, "the ray meets the face it aims at")
        let sphere = try XCTUnwrap(PlatoSprings.pressDirection(eye, ray, springs.restRadius))
        let off = acos(min(1, simd_dot(sphere, axis))) * 180 / .pi
        XCTAssertGreaterThan(off, 10, "the sphere would aim \(off)° from the face")
    }

    /// phase 0 grows its tetra out of the centre: welded on that start it
    /// is one spring sized as a point. A solid welds and sizes where the
    /// clock stopped, so its tetra has its corners at that size, and a
    /// corner press dents it alike at any size and comes home
    func testGrowingTetraWeldsWhereTheClockStopped() {
        let vertices = makeSolid(phase: 0, harmonic: 2)
        XCTAssertEqual(PlatoSprings(vertices).slotOf.max(), 0, "the ball's weld: one spring")
        let full = solidSprings(vertices, range01: 1).restRadius
        var lows = [Float]()
        for range01 in [Float(0.3), 1] {
            let springs = solidSprings(vertices, range01: range01)
            XCTAssertEqual(Set(springs.slotOf).count, 20)
            XCTAssertEqual(springs.restRadius / full, range01, accuracy: 0.02, "sized at range01 \(range01)")
            let press = SpringPress(id: 1, dir: solidDir(vertices, range01, face: false),
                                    pressure: 1, foot: 0.2 * springs.restRadius)
            var low = Float(9), held = Float(0)
            for frame in 0 ..< 1020 {
                springs.step(balloon: 0, range01: range01,
                             presses: frame < 120 ? [press] : [], pressDepth: PlatoSprings.depthMax)
                low = min(low, solidStats(springs, vertices).low)
                if frame == 119 { held = solidStats(springs, vertices).dent }
            }
            XCTAssertGreaterThan(held, 0.3, "range01 \(range01): the corner sinks")
            // the tip sinks depthMax R, 0.6 of a corner's radius: 0.40 measured
            XCTAssertGreaterThan(low, 0.3, "range01 \(range01)")
            XCTAssertLessThan(solidStats(springs, vertices).off, 0.02, "range01 \(range01)")
            lows.append(low)
        }
        XCTAssertEqual(lows[0], lows[1], accuracy: 0.01, "the same dent at either size")
    }

    /// phase 1 spreads a point off each tetra corner toward a cube corner:
    /// welded on its start the two are one spring. Stopped at 0.9 they are
    /// two, and a press on the spread point sinks it, not the corner it left
    func testMorphWeldsWhereTheClockStopped() throws {
        let vertices = makeSolid(phase: 1, harmonic: 0)
        let range01 = Float(0.9)
        func at(_ i: Int) -> SIMD3<Float> { vertices[i].pos0.xyz + (vertices[i].pos1.xyz - vertices[i].pos0.xyz) * range01 }
        let moving = try XCTUnwrap(vertices.indices.first { simd_distance(vertices[$0].pos0.xyz, vertices[$0].pos1.xyz) > 1e-3 })
        let corner = try XCTUnwrap(vertices.indices.first {
            simd_distance(vertices[$0].pos0.xyz, vertices[$0].pos1.xyz) < 1e-5 &&
            simd_distance(vertices[$0].pos0.xyz, vertices[moving].pos0.xyz) < 1e-5 })
        let start = PlatoSprings(vertices, homePull: PlatoSprings.HomePull.solid, solid: true, at: 0)
        XCTAssertEqual(start.slotOf[moving], start.slotOf[corner], "welded on the start: one spring")

        let springs = solidSprings(vertices, range01: range01)
        XCTAssertEqual(Set(springs.slotOf).count, 8)
        XCTAssertNotEqual(springs.slotOf[moving], springs.slotOf[corner])
        let R = springs.restRadius
        let press = SpringPress(id: 1, dir: simd_normalize(at(moving)), pressure: 1, foot: 0.2 * R)
        for _ in 0 ..< 120 {
            springs.step(balloon: 0, range01: range01, presses: [press], pressDepth: 0.5)
        }
        func sink(_ i: Int) -> Float {
            let rest = at(i), rr = simd_length(rest)
            return rr - simd_dot(springs.position(i), rest / rr)
        }
        let target = min(0.5 * R, PlatoSprings.ownShare * simd_length(at(moving)))
        XCTAssertGreaterThan(sink(moving), 0.5 * target, "the spread point sinks")
        XCTAssertLessThan(sink(corner), 0.5 * sink(moving), "the corner it left stays up")
    }

    /// the clock running between a landing and the next frame rebuilds a
    /// solid's springs where it stopped; the landing's impulse moves over
    func testRebuildKeepsTheImpulse() {
        let vertices = makeSolid(phase: 4, harmonic: 1)
        let was = solidSprings(vertices, range01: 0.5)
        was.impulse(at: solidDir(vertices, 0.5, face: false) * was.restRadius, factr: 0.08)
        let now = PlatoSprings(vertices, homePull: PlatoSprings.HomePull.solid, solid: true, at: 0.6)
        now.adopt(was)
        XCTAssertTrue(now.active)
        now.step(balloon: 0, range01: 0.6)
        XCTAssertGreaterThan(solidStats(now, vertices).off, 1e-3, "the impulse lands on the new springs")
        was.step(balloon: 0, range01: 0.5)
        XCTAssertLessThan(solidStats(was, vertices).off, 1e-5, "taken, not copied")
    }

    /// the ball steps every frame; a solid only while it deforms and is
    /// pressed or still ringing
    func testSpringsOn() {
        XCTAssertTrue(PlatoMesh.springsOn(balloon: 0.67, deforms: true, pressed: false, active: false))
        XCTAssertFalse(PlatoMesh.springsOn(balloon: 0, deforms: true, pressed: false, active: false), "a solid at rest")
        XCTAssertTrue(PlatoMesh.springsOn(balloon: 0, deforms: true, pressed: true, active: false))
        XCTAssertTrue(PlatoMesh.springsOn(balloon: 0, deforms: true, pressed: false, active: true), "ringing down")
        XCTAssertFalse(PlatoMesh.springsOn(balloon: 0, deforms: false, pressed: true, active: true), "the clock runs")
    }
}
