//  created by musesum on 2/18/23.
//  Copyright © 2023 com.deepmuse. All rights reserved.

import Foundation

class PlatoCounter {

    enum Direction { case up, down }
    var counterDirection = Direction.up
    var harmonicDirection = Direction.up
    var platoFlos = PlatoFlos.shared

    //var platoFlos.counter = 0    // infinite counter, always rising
    var harmonic = 0   // current triangle subdivision
    var phase = 0      // current phase of running 0...11

    var newPhase = true
    var newHarmonic = true

    var paused = false
    var firstTime = true

    let phaseSteps: Int
    var cycleSteps: Int
    let harmonics = 6  // maximum number of subdivisions
    public let phases = 11    // number of running phases

    var range01 : Float = 0

    init(steps: Int, phase: Int, harmonic: Int) {
        self.phaseSteps = steps
        self.cycleSteps = phaseSteps * phases
        self.harmonic = harmonic
        self.phase = phase
        platoFlos.counter = phase * phaseSteps
        //test()
    }

    func setPhaseHarmonic(_ phaseNow: Int,
                          _ harmonicNow: Int) {
        phase  = max(0, min(phaseNow, phases))
        harmonic = max(0, min(harmonicNow, harmonics))
        platoFlos.counter = (phase * phaseSteps)
    }
    func next() {

        platoFlos.counter += counterDirection == .up ? 1 : -1
        if platoFlos.counter >= cycleSteps {

            counterDirection = .down
            platoFlos.counter = cycleSteps - 1

        } else if platoFlos.counter < 0 {

            counterDirection = .up
            platoFlos.counter = 0

            // new harmonic

            harmonic += harmonicDirection == .up ? 1 : -1
            if harmonic >= harmonics {
                harmonic = 5
                harmonicDirection = .down
                newHarmonic = true

            } else if harmonic < 0 {
                harmonic = 0
                harmonicDirection = .up
                newHarmonic = true
            }
        }
        if phase != platoFlos.counter / phaseSteps {
            phase = platoFlos.counter / phaseSteps
            newPhase = true
        }

        range01 = Float(platoFlos.counter % phaseSteps) / Float(phaseSteps)
        logCounter()
    }
    func logCountNow() {
        let phaseStr = "phase: \(phase) "
        let harmonicDir = harmonicDirection == .up ? ">" : "<"
        let harmonicStr = "harmonic: \(harmonic) \(harmonicDir) "
        let counterDir = counterDirection == .up ? ">" : "<"
        let counterStr = "counter: \(platoFlos.counter) \(counterDir)"
        print(phaseStr + harmonicStr + counterStr)
    }

    func logCounter() {
//        print("\(counter):  harmonic: \(harmonic)  phase: \(phase)  range01: \(range01.digits(3...3))")
    }
    func test() {
        for i in stride(from:    0, to:   210, by:  1) { platoFlos.counter = i; next() } ; print("_1_")
        for i in stride(from: 1290, to:  1410, by:  1) { platoFlos.counter = i; next() } ; print("_2_")
        for i in stride(from: 2000, to: 40000, by: 99) { platoFlos.counter = i; next() } ; print("_3_")
    }
}
