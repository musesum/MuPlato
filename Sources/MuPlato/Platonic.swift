// Platonic.swift

import Foundation
import Collections
import Vision
import UIKit

open class Platonic {

    var counter: PlatoCounter
    var plaTrii: PlaTrii
    var plaTriis = [PlaTrii]()

    var device: MTLDevice 

    var harmonicSteps = 2000
    var colorCount = 70
    var colorStride = 1

    public var platoOps = PlatoOps([

        .showCube,
        //.showPlato,
        //.reflectCube,
        //.cameraBack,
        //.cameraFront,
        //.faceMask,
            .trackMotion,
        //.colorizeTri,
        .colorShade,
        .invertShade,
        .drawFill,
    ])

    init(_ device: MTLDevice) {

        self.plaTrii = PlaTrii([])
        self.device = device
        self.counter = PlatoCounter(8000, platoOps.hasCamera, harmonic: 4)

        let sd = MTLSamplerDescriptor()
        sd.minFilter = .nearest
        sd.magFilter = .linear

        nextCounter()
    }

    func nextCounter() {

        counter.next()

        if counter.newHarmonic {

            Tri01.reset()
            buildAll()

            for phase in 0 ..< plaTriis.count {
                let plaTrii = plaTriis[phase]
                _ = plaTrii.trisect(counter.harmonic, harmonicSteps, phase)
            }
            for i in 0 ..< plaTriis.count {

                let plaTrii = plaTriis[i]

                logBuildCounter(i)
                for tri in plaTrii.tri01s {
                    tri.setId(i)
                }
            }
        }
        if counter.newPhase {
            logCounter()
            plaTrii = plaTriis[counter.phase]
            plaTrii.updateBuffers(device, counter, self)
        }
    }
    
    func logBuildCounter(_ i: Int) {
        //print("build phase: \(i) harmonic: \(counter.harmonic )")
    }
    func logCounter() {
        print("phase: \(counter.phase)  harmonic: \(counter.harmonic) counter: \(counter.counter)  \(counter.increasing ? ">" : "<")")
    }
    func ranges() -> vector_float4 {
        return vector_float4(counter.range01,
                             Float(harmonicSteps),
                             Float(colorCount),
                             Float(colorStride))
    }

}
