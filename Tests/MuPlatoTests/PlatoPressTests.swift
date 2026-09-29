// created by musesum on 9/28/26

import XCTest
import simd
@testable import MuPlato

/// a held finger or pencil on the ico ball: the tip sinks as deep as its
/// pressure, the springs push back, and the ball rings down once it lifts.
/// the numbers were measured on these meshes with an optimised build of
/// the same arithmetic before the change landed
extension PlatoSpringsTests { // + Press

    /// springs past the drag ramp (0.7 → 0.99 in 73 steps)
    func warmBall(phase: Int, harmonic: Int) -> ([PlatoVertex], PlatoSprings) {
        let vertices = makeBall(phase: phase, harmonic: harmonic).vertices!
        let springs = PlatoSprings(vertices)
        for _ in 0 ..< 100 { springs.step(balloon: 0.67, range01: 0) }
        return (vertices, springs)
    }

    /// deepest dent below the rest sphere and the lowest surface, both in
    /// rest radii, measured along each vertex's own rest direction
    func dent(_ springs: PlatoSprings, _ vertices: [PlatoVertex]) -> (dent: Float, low: Float) {
        var dent = Float(-9), low = Float(9)
        let R = springs.restRadius
        for i in vertices.indices {
            let rest = vertices[i].pos0.xyz * springs.inflate
            let rr = simd_length(rest)
            guard rr > 1e-6 else { continue }
            let r = simd_dot(springs.position(i), rest / rr)
            dent = max(dent, (rr - r) / R)
            low = min(low, r / R)
        }
        return (dent, low)
    }

    func step(_ springs: PlatoSprings, _ presses: [SpringPress], depth: Float) {
        springs.step(balloon: 0.67, range01: 0, presses: presses, pressDepth: depth)
    }

    /// a held press settles at pressure × press radii and no deeper, and
    /// the springs push back harder the deeper it goes
    func testHeldPressFollowsPressure() {
        for (phase, harmonic) in [(1, 2), (4, 2), (10, 2)] {
            var pushes = [Float]()
            for p in [Float(0.25), 0.5, 1] {
                let (vertices, springs) = warmBall(phase: phase, harmonic: harmonic)
                let dir = simd_normalize(vertices[0].pos0.xyz)
                let press = SpringPress(id: 7, dir: dir, pressure: p, foot: 0.2 * springs.restRadius)
                var peak = Float(0)
                for _ in 0 ..< 120 {
                    step(springs, [press], depth: 0.5)
                    peak = max(peak, dent(springs, vertices).dent)
                }
                let held = dent(springs, vertices).dent
                let tag = "phase \(phase) harmonic \(harmonic) pressure \(p)"
                XCTAssertEqual(held, p * 0.5, accuracy: 0.01, tag)
                XCTAssertLessThanOrEqual(peak, held + 0.01, "\(tag): overshoot \(peak)")
                pushes.append(springs.pushBack)
            }
            XCTAssertLessThan(pushes[0], pushes[1], "phase \(phase): push back \(pushes)")
            XCTAssertLessThan(pushes[1], pushes[2], "phase \(phase): push back \(pushes)")
        }
    }

    /// press 0 is the old single tap, bit for bit, however hard the touch
    func testPressZeroIsTheOldTap() {
        let vertices = makeBall(phase: 4, harmonic: 2).vertices!
        let a = PlatoSprings(vertices)
        let b = PlatoSprings(vertices)
        let press = SpringPress(id: 7, dir: simd_normalize(vertices[0].pos0.xyz), pressure: 1, foot: 0)
        for frame in 0 ..< 300 {
            if frame == 5 {
                a.impulse(at: vertices[0].pos0.xyz * a.inflate)
                b.impulse(at: vertices[0].pos0.xyz * b.inflate)
            }
            a.step(balloon: 0.67, range01: 0)
            step(b, [press], depth: 0)
            for i in vertices.indices where a.position(i) != b.position(i) {
                return XCTFail("frame \(frame) vertex \(i) moved")
            }
        }
    }

    /// a light fingertip tap at the default press rings the ball as the old
    /// tap did: the impulse still does the work, the short press adds
    /// nothing on a fine mesh and 5% on the 34-spring default ball
    func testLightTapIsTheOldTap() {
        for (phase, harmonic, most) in [(1, 2, Float(1.06)), (4, 2, 1.001), (10, 2, 1.001)] {
            var peaks = [Float]()
            for tapped in [false, true] {
                let (vertices, springs) = warmBall(phase: phase, harmonic: harmonic)
                let dir = simd_normalize(vertices[0].pos0.xyz)
                springs.impulse(at: vertices[0].pos0.xyz * springs.inflate)
                var peak = Float(0)
                for frame in 0 ..< 300 {
                    let held = tapped && frame < 6
                    step(springs, held ? [SpringPress(id: 7, dir: dir, pressure: 0.25, foot: 0)] : [], depth: 0.5)
                    peak = max(peak, dent(springs, vertices).dent)
                }
                peaks.append(peak)
            }
            let ratio = peaks[1] / peaks[0]
            XCTAssertGreaterThanOrEqual(ratio, 0.999, "phase \(phase): \(peaks)")
            XCTAssertLessThanOrEqual(ratio, most, "phase \(phase): \(peaks)")
        }
    }

    /// the deepest press never pushes the surface through the centre: one
    /// press, two 60° apart, or one dragged a quarter turn. the coarse balls
    /// clamp every footprint to the widest; the fine ones press with the
    /// pencil's narrowest tip, where the slope cap binds on phase 10 subdiv
    /// 3. a press slider past its ceiling reads as the ceiling
    func testPressNeverCavesIn() {
        for (phase, harmonic, footR) in [(1, 2, PlatoSprings.footMax), (4, 2, PlatoSprings.footMax),
                                         (10, 2, Float(0)), (10, 3, Float(0))] {
            for scene in ["one", "two", "drag"] {
                let (vertices, springs) = warmBall(phase: phase, harmonic: harmonic)
                let u = simd_normalize(vertices[0].pos0.xyz)
                let side = simd_normalize(simd_cross(u, abs(u.x) < 0.9 ? SIMD3<Float>(1, 0, 0) : SIMD3<Float>(0, 1, 0)))
                let foot = footR * springs.restRadius
                var low = Float(9)
                for frame in 0 ..< 400 {
                    var presses = [SpringPress]()
                    if frame < 300 {
                        switch scene {
                        case "two":
                            let a = Float.pi / 3
                            presses = [SpringPress(id: 1, dir: u, pressure: 1, foot: foot),
                                       SpringPress(id: 2, dir: simd_normalize(u * cos(a) + side * sin(a)), pressure: 1, foot: foot)]
                        case "drag":
                            let a = Float.pi / 2 * min(1, Float(frame) / 120)
                            presses = [SpringPress(id: 1, dir: simd_normalize(u * cos(a) + side * sin(a)), pressure: 1, foot: foot)]
                        default:
                            presses = [SpringPress(id: 1, dir: u, pressure: 1, foot: foot)]
                        }
                    }
                    step(springs, presses, depth: PlatoSprings.depthMax)
                    XCTAssertTrue(springs.energy.isFinite, "\(scene) frame \(frame)")
                    low = min(low, dent(springs, vertices).low)
                }
                XCTAssertGreaterThanOrEqual(low, 0.12, "phase \(phase) foot \(footR) \(scene): the surface fell to \(low)")
            }
        }
        let vertices = makeBall(phase: 4, harmonic: 2).vertices!
        let ceiling = PlatoSprings(vertices), past = PlatoSprings(vertices)
        let press = SpringPress(id: 1, dir: simd_normalize(vertices[0].pos0.xyz), pressure: 1, foot: 0)
        for _ in 0 ..< 60 {
            step(ceiling, [press], depth: PlatoSprings.depthMax)
            step(past, [press], depth: 5)
        }
        for i in vertices.indices {
            XCTAssertEqual(ceiling.position(i), past.position(i))
        }
    }

    /// lift a full press and the ball rings down onto the built sphere
    func testReleasedPressRingsDown() {
        for (phase, harmonic) in [(1, 2), (4, 2)] {
            let (vertices, springs) = warmBall(phase: phase, harmonic: harmonic)
            let press = SpringPress(id: 7, dir: simd_normalize(vertices[0].pos0.xyz),
                                    pressure: 1, foot: 0.2 * springs.restRadius)
            springs.impulse(at: vertices[0].pos0.xyz * springs.inflate)
            for _ in 0 ..< 120 { step(springs, [press], depth: 0.5) }
            var still = -1
            for frame in 1 ... 4000 {
                step(springs, [], depth: 0.5)
                if still < 0, !springs.active { still = frame }
            }
            let tag = "phase \(phase) harmonic \(harmonic)"
            XCTAssertGreaterThan(still, 0, "\(tag): never came to rest")
            XCTAssertLessThanOrEqual(still, 2500, "\(tag): rang \(still) steps")
            XCTAssertLessThan(springs.energy, 1e-6, tag)
            var worst = Float(0)
            for i in vertices.indices {
                let rest = vertices[i].pos0.xyz * springs.inflate
                worst = max(worst, simd_length(springs.position(i) - rest) / simd_length(rest))
            }
            XCTAssertLessThan(worst, 1e-4, "\(tag): a vertex rests \(worst) off the sphere")
        }
    }

    /// a hard pencil jab on the finest ball: the slope cap keeps the narrow
    /// tip from folding the mesh into a crease that never rings out
    func testNarrowPressDoesNotFold() {
        let (vertices, springs) = warmBall(phase: 10, harmonic: 3)
        let press = SpringPress(id: 1, dir: simd_normalize(vertices[0].pos0.xyz), pressure: 1, foot: 0)
        for _ in 0 ..< 12 { step(springs, [press], depth: PlatoSprings.depthMax) }
        for _ in 0 ..< 1500 { step(springs, [], depth: PlatoSprings.depthMax) }
        XCTAssertLessThan(springs.energy, 1e-4, "still folded: energy \(springs.energy)")
    }

    /// the sight ray meets the ball at its front; an eye inside takes the
    /// wall ahead; a finger just off the rim presses the rim, one further
    /// off lets go, and a ball behind the eye is never pressed
    func testPressDirection() {
        func near(_ a: SIMD3<Float>?, _ b: SIMD3<Float>, _ tag: String) {
            guard let a else { return XCTFail("\(tag): nil") }
            XCTAssertLessThan(simd_length(a - b), 1e-5, "\(tag): \(a)")
        }
        let ahead = SIMD3<Float>(0, 0, 1)
        near(PlatoSprings.pressDirection([0, 0, -4], ahead, 1.8), [0, 0, -1], "front")
        near(PlatoSprings.pressDirection([0, 0, -1], ahead, 1.8), [0, 0, 1], "inside")
        near(PlatoSprings.pressDirection([1.85, 0, -4], ahead, 1.8, reach: 0.1), [1, 0, 0], "rim")
        XCTAssertNil(PlatoSprings.pressDirection([1.85, 0, -4], ahead, 1.8), "no reach, no rim")
        XCTAssertNil(PlatoSprings.pressDirection([3, 0, -4], ahead, 1.8, reach: 0.1), "off the ball")
        XCTAssertNil(PlatoSprings.pressDirection([0, 0, 4], ahead, 1.8, reach: 0.1), "behind the eye")
    }

    /// the narrowest tip keeps its depth between vertices: a press at a
    /// face centre sinks nearly as far as one right on a vertex
    func testFaceCentredPressKeepsDepth() {
        for (phase, harmonic) in [(4, 2), (10, 2)] {
            var dents = [Float]()
            for centred in [false, true] {
                let (vertices, springs) = warmBall(phase: phase, harmonic: harmonic)
                var t = 0
                while springs.slotOf[t] == springs.slotOf[t+1] ||
                        springs.slotOf[t+1] == springs.slotOf[t+2] ||
                        springs.slotOf[t] == springs.slotOf[t+2] { t += 3 }
                let a = vertices[t].pos0.xyz, b = vertices[t+1].pos0.xyz, c = vertices[t+2].pos0.xyz
                let dir = simd_normalize(centred ? a + b + c : a)
                for _ in 0 ..< 120 {
                    step(springs, [SpringPress(id: 7, dir: dir, pressure: 0.5, foot: 0)], depth: 0.5)
                }
                dents.append(dent(springs, vertices).dent)
            }
            XCTAssertGreaterThanOrEqual(dents[1] / dents[0], 0.85, "phase \(phase): vertex \(dents[0]) face \(dents[1])")
        }
    }

    /// two fingers on one spot press as one: the deepest tip, not the sum
    func testTouchesTakeTheDeepestTip() {
        var dents = [Float]()
        for fingers in 1 ... 2 {
            let (vertices, springs) = warmBall(phase: 4, harmonic: 2)
            let dir = simd_normalize(vertices[0].pos0.xyz)
            let presses = (0 ..< fingers).map {
                SpringPress(id: $0, dir: dir, pressure: 1, foot: 0.2 * springs.restRadius)
            }
            for _ in 0 ..< 120 { step(springs, presses, depth: 0.5) }
            dents.append(dent(springs, vertices).dent)
        }
        XCTAssertEqual(dents[0], dents[1], accuracy: 1e-6)
    }

    /// a flatter finger's wider silhouette sinks more of the ball under it
    /// than a pencil tip at the same pressure
    func testWiderSilhouettePressesMoreVertices() {
        var sunk = [Int]()
        for footR in [Float(0), PlatoSprings.footMax] { // the narrowest here is 2 edges, 0.26 radii
            let (vertices, springs) = warmBall(phase: 10, harmonic: 2)
            let dir = simd_normalize(vertices[0].pos0.xyz)
            let press = SpringPress(id: 7, dir: dir, pressure: 0.5, foot: footR * springs.restRadius)
            for _ in 0 ..< 120 { step(springs, [press], depth: 0.5) }
            let R = springs.restRadius
            var slots = Set<Int>()
            for i in vertices.indices {
                let rest = vertices[i].pos0.xyz * springs.inflate
                let r = simd_dot(springs.position(i), simd_normalize(rest))
                if simd_length(rest) - r > 0.05 * R { slots.insert(springs.slotOf[i]) }
            }
            sunk.append(slots.count)
        }
        XCTAssertGreaterThan(sunk[1], sunk[0] * 2, "pencil sinks \(sunk[0]) springs, a flat finger \(sunk[1])")
    }
}
