// created by musesum on 9/29/26

import XCTest
import simd
@testable import MuPlato

/// a press from inside the solid lifts its surface out: the visionOS
/// thumb-middle pinch begun inside. The mirror of the held press: as high
/// as a press from outside sinks, the tip rigid under the slots, and the
/// springs bring it home once it lets go
extension PlatoSpringsTests { // + Outward

    /// the highest rise above the rest, rest radii, along each vertex's own
    /// rest direction, and the farthest any slot stands off its rest. The
    /// rest is home × inflate: the ball rests swollen, a solid at 1
    func rise(_ springs: PlatoSprings, _ vertices: [PlatoVertex]) -> (rise: Float, off: Float) {
        var rise = Float(-9), off = Float(0)
        let R = springs.restRadius
        for i in vertices.indices {
            let p = springs.position(i)
            let rest = (p - springs.offset(i)) * springs.inflate
            let rr = simd_length(rest)
            guard rr > 1e-6 else { continue }
            rise = max(rise, (simd_dot(p, rest / rr) - rr) / R)
            off = max(off, simd_distance(p, rest) / R)
        }
        return (rise, off)
    }

    /// on the ball the lift holds at pressure × press radii, the balloon
    /// pushing the same way held off by the grip, and the ball rings down
    /// onto its sphere once it lets go, as a released press does
    func testOutwardPressLifts() {
        for (phase, harmonic) in [(1, 2), (4, 2), (10, 2)] {
            for p in [Float(0.25), 0.5] {
                let (vertices, springs) = warmBall(phase: phase, harmonic: harmonic)
                let dir = simd_normalize(vertices[0].pos0.xyz)
                let press = SpringPress(id: 7, dir: dir, pressure: p,
                                        foot: 0.2 * springs.restRadius, outward: true)
                var peak = Float(-9)
                for _ in 0 ..< 120 {
                    step(springs, [press], depth: 0.5)
                    peak = max(peak, rise(springs, vertices).rise)
                }
                let held = rise(springs, vertices).rise
                let tag = "phase \(phase) harmonic \(harmonic) pressure \(p)"
                XCTAssertEqual(held, p * 0.5, accuracy: 0.02, tag)
                XCTAssertLessThanOrEqual(peak, held + 0.02, "\(tag): overshoot \(peak)")
                XCTAssertGreaterThan(springs.pushBack, 0, "\(tag): the springs pull against the grip")
                var still = -1
                for frame in 1 ... 4000 {
                    step(springs, [], depth: 0.5)
                    if still < 0, !springs.active { still = frame }
                }
                XCTAssertTrue(springs.energy.isFinite, tag)
                XCTAssertGreaterThan(still, 0, "\(tag): never came to rest")
                XCTAssertLessThanOrEqual(still, 2500, "\(tag): rang \(still) steps")
                XCTAssertLessThan(rise(springs, vertices).off, 1e-3, "\(tag): home")
            }
        }
    }

    /// a platonic solid, the clock off: lifted from inside at a corner or a
    /// face, as deep as the slider goes, it comes home with no fold
    func testOutwardPressOnASolid() {
        for (phase, harmonic) in [(1, 2), (4, 0), (10, 1)] {
            for face in [false, true] {
                let vertices = makeSolid(phase: phase, harmonic: harmonic)
                let springs = solidSprings(vertices, range01: 0.5)
                let press = SpringPress(id: 1, dir: solidDir(vertices, 0.5, face: face), pressure: 1,
                                        foot: 0.2 * springs.restRadius, outward: true)
                var held = Float(0)
                for frame in 0 ..< 1020 {
                    springs.step(balloon: 0, range01: 0.5,
                                 presses: frame < 120 ? [press] : [], pressDepth: PlatoSprings.depthMax)
                    if frame == 119 { held = rise(springs, vertices).rise }
                }
                let tag = "phase \(phase) harmonic \(harmonic) face \(face)"
                XCTAssertTrue(springs.energy.isFinite, tag)
                XCTAssertGreaterThan(held, 0.3, "\(tag): the surface lifts")
                XCTAssertLessThan(rise(springs, vertices).off, 0.02, "\(tag): folded")
            }
        }
    }

    /// an inward and an outward press on one spot: the one that moves the
    /// slot furthest wins, never the sum
    func testFurthestTipWinsEitherWay() {
        let (vertices, springs) = warmBall(phase: 4, harmonic: 2)
        let dir = simd_normalize(vertices[0].pos0.xyz)
        let foot = 0.2 * springs.restRadius
        let lift = SpringPress(id: 1, dir: dir, pressure: 0.5, foot: foot, outward: true)
        let sink = SpringPress(id: 2, dir: dir, pressure: 0.25, foot: foot)
        for _ in 0 ..< 120 { step(springs, [lift, sink], depth: 0.5) }
        XCTAssertEqual(rise(springs, vertices).rise, 0.25, accuracy: 0.02, "the lift is the larger")
        let deeper = SpringPress(id: 2, dir: dir, pressure: 1, foot: foot)
        for _ in 0 ..< 120 { step(springs, [lift, deeper], depth: 0.5) }
        XCTAssertEqual(dent(springs, vertices).dent, 0.5, accuracy: 0.02, "now the sink is")
    }
}
