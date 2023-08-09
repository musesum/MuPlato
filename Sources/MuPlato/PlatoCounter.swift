//  Created by warren on 2/18/23.
//  Copyright © 2023 com.deepmuse. All rights reserved.
//

import Foundation

class PlatoCounter {

    var counter = 0    // infinite counter, always rising
    var harmonic = 0   // current triangle subdivision
    var phase = 0      // current phase of morphing 0...11
    var step = 0
    var newPhase = true

    var newHarmonic = true
    var paused = false
    var firstTime = true
    var increasing = true

    let steps: Int
    let harmonics = 6  // maximum number of subdivisions
    public let phases = 11    // number of morphing phases

    let phaseMod: Int
    let harmoDiv: Int
    let harmoMod: Int

    var range01: Float { Float(step) / Float(steps) }

    init(_ counter: Int, _ viaFrame: Bool, harmonic: Int = 0) {
        self.counter = counter
        self.harmonic = harmonic
        self.steps = viaFrame ? 120 : 200

        phaseMod = phases * 2
        harmoDiv = steps * phaseMod
        harmoMod = harmonics * 2
        //logConstants()
        //test()
    }

    func setPhase(_ p: CGPoint) {
        let newStep  = Int(CGFloat(harmoDiv) * p.x)
        let newHarmo = Int(CGFloat(harmoMod) * p.y)
        counter = newHarmo * newStep
    }
    func next(_ count: Int? = nil) {

        if firstTime {
            firstTime = false
            newPhase = true
            newHarmonic = true
            return
        }
        if paused {
            newPhase = false
            newHarmonic = false
            return
        }

        counter = count ?? counter + 1

        step = counter % steps

        let phasePrev = phase
        phase = (counter / steps) % phaseMod
        if phase >= phases {
            phase = phaseMod - phase -  1
            step = steps - step
            increasing = false
        } else {
            increasing = true
        }
        newPhase = phase != phasePrev

        let harmonicPrev = harmonic
        harmonic = (counter / harmoDiv) % harmoMod
        if harmonic >= harmonics {
            harmonic = harmoMod - harmonic
        }
        newHarmonic = harmonic != harmonicPrev
        newPhase = newPhase || newHarmonic
        
        logCounter()
    }

    func logConstants() {
        print("phaseMod:\(phaseMod):  harmoDiv:\(harmoDiv)  harmoMod:\(harmoMod)  steps:\(steps)  n:\(range01.digits(3...3))")
    }
    func logCounter() {
        if phase != 100 { return }
            print("\(counter):  h: \(harmonic)  p: \(phase)  s: \(String(step).padding(toLength: 4, withPad: " ", startingAt: 0))  n: \(range01.digits(3...3))")
    }
    func test() {
        for i in stride(from:    0, to:   210, by:  1) { next(i) } ; print("_1_")
        for i in stride(from: 1290, to:  1410, by:  1) { next(i) } ; print("_2_")
        for i in stride(from: 2000, to: 40000, by: 99) { next(i) } ; print("_3_")
    }
}
