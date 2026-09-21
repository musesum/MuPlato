import XCTest
import MuFlo
@testable import MuPlato

/// scratch probe: harmonic sequence and edit anchoring
final class PlatoCounterTests: XCTestCase {

    /// no `plato` node in the root, so the binds no-op and the flo-backed
    /// phase / harmonic stay at their Swift defaults — the counter is driven
    /// directly, which is what these checks are about
    func makeCounter(steps: Int) -> (PlatoCounter, PlatoFlo) {
        let flo = PlatoFlo(Flo("√"))
        let counter = PlatoCounter(flo, steps: steps, phase: 0, harmonic: 0)
        return (counter, flo)
    }

    /// every harmonic step must raise newHarmonic, and the ping-pong must
    /// visit 0…6 inclusive without skipping or repeating a reflection
    func testHarmonicSequence() {
        let steps = 4
        let (counter, flo) = makeCounter(steps: steps)
        var seen = [Int]()
        var missedRebuild = 0
        var lastHarmonic = counter.harmonic

        // long enough for a full up-and-down harmonic traverse
        for _ in 0 ..< (steps * counter.phases * 40) {
            counter.next()
            if counter.harmonic != lastHarmonic {
                if !counter.newHarmonic { missedRebuild += 1 }
                lastHarmonic = counter.harmonic
                seen.append(counter.harmonic)
            }
            // the model clears the flags after rebuilding
            counter.newHarmonic = false
            counter.newPhase = false
            _ = flo
        }
        XCTAssertEqual(missedRebuild, 0, "harmonic changed without newHarmonic")
        XCTAssertTrue(seen.contains(6), "harmonic 6 never reached; saw \(seen)")
        XCTAssertTrue(seen.contains(0), "harmonic 0 never reached; saw \(seen)")
        XCTAssertEqual(seen.max(), 6, "harmonic overshot; saw \(seen)")
        XCTAssertEqual(seen.min(), 0, "harmonic undershot; saw \(seen)")
        print("harmonic sequence: \(seen.prefix(20))")
    }

    /// setHarmonic must not move the sweep; setPhase must anchor it and rise
    func testEditAnchoring() {
        let steps = 200
        let (counter, flo) = makeCounter(steps: steps)

        // walk into the descending leg
        for _ in 0 ..< (steps * counter.phases + 50) { counter.next() }
        XCTAssertEqual(counter.counterDirection, .down)
        let held = flo.counter

        counter.setHarmonic(3)
        XCTAssertEqual(counter.harmonic, 3)
        XCTAssertEqual(flo.counter, held, "harmonic edit moved the sweep")
        XCTAssertTrue(counter.newHarmonic, "harmonic edit skipped the rebuild")

        counter.setPhase(4)
        XCTAssertEqual(flo.counter, 4 * steps, "phase edit failed to anchor")
        XCTAssertEqual(counter.counterDirection, .up,
                       "phase edit left the sweep descending")
        counter.next()
        XCTAssertEqual(counter.phase, 4, "sweep left the phase just chosen")
    }

    /// phase must clamp to the highest valid platoPhases index, not to `phases`
    func testPhaseClamp() {
        let (counter, flo) = makeCounter(steps: 200)
        counter.setPhase(99)
        XCTAssertEqual(counter.phase, counter.phases - 1)
        XCTAssertLessThan(flo.counter, counter.cycleSteps)

        counter.setHarmonic(99)
        XCTAssertEqual(counter.harmonic, counter.harmonics)
    }
}
