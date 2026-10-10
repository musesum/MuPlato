// created by musesum on 9/29/26

import XCTest
import simd
import MuFlo
@testable import MuPlato

/// plato.spring: a light touch only presses, a deep fast landing also drops
/// the impulse (PressAttack), and the disk spreads the footprint a touch
/// covers (SpringPress.footprint, SpringPress.spread). The shares were measured with an optimised build
/// of the same arithmetic before the change landed
extension PlatoSpringsTests { // + Attack

    static let frame = TimeInterval(1) / 60

    /// every sample's thrust summed, for pressures one frame apart from 0
    func thrust(_ pressures: [Float], after: TimeInterval = 0) -> Float {
        var attack = PressAttack(start: 0)
        var sum = Float(0)
        for (i, p) in pressures.enumerated() {
            sum += attack.factr(pressure: p, time: after + TimeInterval(i) * Self.frame)
        }
        return sum
    }

    /// a light fingertip or a light pencil fires nothing; a deep landing in
    /// one or two frames fires the whole tap; a medium one its share
    func testAttackScalesWithTheLanding() {
        XCTAssertEqual(thrust([0.25, 0.25, 0.25]), 0, "light fingertip")
        XCTAssertEqual(thrust([0.15, 0.15]), 0, "light pencil")
        XCTAssertEqual(thrust([1]), PressAttack.whole, accuracy: 1e-7, "one frame")
        XCTAssertEqual(thrust([0.5, 1]), PressAttack.whole, accuracy: 1e-7, "two frames")
        XCTAssertEqual(thrust([0.6]), PressAttack.whole * 0.394, accuracy: 0.0005, "medium")
        XCTAssertEqual(thrust([0.62]), PressAttack.whole * 0.436, accuracy: 0.0005, "a finger one step flat")
    }

    /// a slow firm press sinks all the way and drops nothing: a 600 ms ramp
    /// is still under the low end when the window closes
    func testSlowPressDropsNothing() {
        let ramp = (0 ..< 36).map { Float($0 + 1) / 36 }
        XCTAssertEqual(thrust(ramp), 0)
    }

    /// once the window closes a jab only deepens the press; a landing that
    /// eases back and deepens again never fires more than the whole tap
    func testWindowClosesAndNeverRefires() {
        var attack = PressAttack(start: 0)
        XCTAssertEqual(attack.factr(pressure: 0.25, time: 0), 0)
        XCTAssertEqual(attack.factr(pressure: 1, time: 0.2), 0, "jab after the window")
        XCTAssertEqual(thrust([1, 0.4, 1, 0.2, 1]), PressAttack.whole, accuracy: 1e-7)
        XCTAssertEqual(thrust([1], after: PressAttack.window), 0, "the window is half open")
    }

    /// a fifth of the ball at the disk's default, widened by a finger's
    /// silhouette and halved for the pencil; the disk spreads it
    func testFootprint() {
        func foot(_ silhouette: Float, _ r: Float = 1) -> Float {
            SpringPress.footprint(silhouette: silhouette, ballRadius: r)
        }
        XCTAssertEqual(foot(21), 0.2, accuracy: 1e-6, "a light fingertip")
        XCTAssertEqual(foot(31.3), 0.298, accuracy: 0.001, "one silhouette step flatter")
        XCTAssertEqual(foot(42), 0.4, accuracy: 1e-6, "a thumb")
        XCTAssertEqual(foot(63), 0.4, accuracy: 1e-6, "no wider than twice")
        XCTAssertEqual(foot(10), 0.2, accuracy: 1e-6, "no narrower than a fingertip")
        XCTAssertEqual(foot(0), 0.1, accuracy: 1e-6, "the pencil")
        XCTAssertEqual(foot(21, 3), 0.6, accuracy: 1e-6, "in model units")
        XCTAssertEqual(SpringPress.spread(cover: 0.4), 1, accuracy: 1e-6, "the default is the mesh's own width")
        XCTAssertEqual(SpringPress.spread(cover: 0), 0.2, accuracy: 1e-6)
        XCTAssertEqual(SpringPress.spread(cover: 1), 2.2, accuracy: 1e-6)
        XCTAssertEqual(SpringPress.spread(cover: 2), 2.2, accuracy: 1e-6, "cover holds to 0…1")
    }

    /// Σ dent over the welded slots, ball radii: how much of the ball sinks
    func sunk(_ springs: PlatoSprings, _ vertices: [PlatoVertex]) -> Float {
        var seen = Set<Int>(), sum = Float(0)
        for i in vertices.indices where seen.insert(springs.slotOf[i]).inserted {
            let rest = vertices[i].pos0.xyz * springs.inflate
            let rr = simd_length(rest)
            guard rr > 1e-6 else { continue }
            sum += max(0, rr - simd_dot(springs.position(i), rest / rr)) / springs.restRadius
        }
        return sum
    }

    /// the disk widens a held fingertip's dent on every ball, where 2 edges
    /// pass footMax on the default 34-spring ball and on phase 4, and every
    /// footprint used to press the same half radius; the default cover
    /// presses as before it had a disk. Narrower narrows phase 4 and up; on
    /// the default ball a press moves one vertex, or a face's three, and
    /// its springs carry the rest whatever the tip's width
    func testCoverSpreadsOnEveryBall() {
        for (phase, harmonic) in [(1, 2), (4, 2), (10, 2)] {
            var sums = [Float]()
            for cover in [Float(0), SpringPress.coverDefault, 1] {
                let (vertices, springs) = warmBall(phase: phase, harmonic: harmonic)
                let dir = simd_normalize(vertices[0].pos0.xyz)
                let foot = SpringPress.footprint(silhouette: 21, ballRadius: springs.restRadius)
                let press = SpringPress(id: 7, dir: dir, pressure: 0.5, foot: foot,
                                        spread: SpringPress.spread(cover: cover))
                for _ in 0 ..< 120 { step(springs, [press], depth: 0.5) }
                XCTAssertEqual(dent(springs, vertices).dent, 0.25, accuracy: 0.01,
                               "phase \(phase) cover \(cover): the tip still sinks as deep")
                sums.append(sunk(springs, vertices))
            }
            let tag = "phase \(phase): \(sums)"
            XCTAssertGreaterThan(sums[2], sums[1] * 1.1, tag)
            if phase == 4 { XCTAssertLessThan(sums[0], sums[1] * 0.9, tag) }
            if phase == 10 { XCTAssertLessThanOrEqual(sums[0], sums[1] + 1e-4, tag) }
        }
        // spread 1 is the width the mesh allowed before the disk, bit for bit
        let vertices = makeBall(phase: 4, harmonic: 2).vertices!
        let a = PlatoSprings(vertices), b = PlatoSprings(vertices)
        let dir = simd_normalize(vertices[0].pos0.xyz)
        for _ in 0 ..< 60 {
            step(a, [SpringPress(id: 1, dir: dir, pressure: 1, foot: 0.2 * a.restRadius)], depth: 0.5)
            step(b, [SpringPress(id: 1, dir: dir, pressure: 1, foot: 0.2 * b.restRadius,
                                 spread: SpringPress.spread(cover: SpringPress.coverDefault))], depth: 0.5)
        }
        for i in vertices.indices { XCTAssertEqual(a.position(i), b.position(i)) }
    }

    /// a deep fast tap drops the old single tap, bit for bit
    func testDeepFastTapIsTheOldImpulse() {
        let vertices = makeBall(phase: 4, harmonic: 2).vertices!
        let a = PlatoSprings(vertices)
        let b = PlatoSprings(vertices)
        var attack = PressAttack(start: 3)
        let hit = vertices[0].pos0.xyz * a.inflate
        a.impulse(at: hit)
        b.impulse(at: hit, factr: attack.factr(pressure: 1, time: 3))
        for frame in 0 ..< 120 {
            a.step(balloon: 0.67, range01: 0)
            b.step(balloon: 0.67, range01: 0)
            for i in vertices.indices where a.position(i) != b.position(i) {
                return XCTFail("frame \(frame) vertex \(i) moved")
            }
        }
    }

    /// a light fingertip held a second at the default depth and cover dents
    /// the ball to its pressure and no deeper: no impulse rings it, where
    /// the old tap overshot 2.3 times on phase 4 and 5.2 on phase 10
    func testLightTouchOnlyPresses() {
        for (phase, harmonic) in [(1, 2), (4, 2), (10, 2)] {
            let (vertices, springs) = warmBall(phase: phase, harmonic: harmonic)
            let dir = simd_normalize(vertices[0].pos0.xyz)
            let foot = SpringPress.footprint(silhouette: 21, ballRadius: springs.restRadius)
            let press = SpringPress(id: 7, dir: dir, pressure: 0.25, foot: foot)
            var attack = PressAttack(start: 0)
            var peak = Float(0)
            for frame in 0 ..< 60 {
                let factr = attack.factr(pressure: 0.25, time: TimeInterval(frame) * Self.frame)
                if factr > 0 { springs.impulse(at: dir * springs.restRadius, factr: factr) }
                step(springs, [press], depth: 0.5)
                peak = max(peak, dent(springs, vertices).dent)
            }
            XCTAssertEqual(attack.fired, 0, "phase \(phase)")
            XCTAssertLessThanOrEqual(peak, 1.1 * 0.25 * 0.5, "phase \(phase): peak \(peak)")
            XCTAssertEqual(dent(springs, vertices).dent, 0.25 * 0.5, accuracy: 0.01, "phase \(phase)")
        }
    }
}
