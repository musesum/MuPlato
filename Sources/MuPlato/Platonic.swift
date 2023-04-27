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

    let platoFlo = PlatoFlo.shared
    let cameraFlo = CameraFlo.shared
    var platoPhase = CGPoint.zero

    var platoColors = CGPoint.zero
    var colorCount: Int { Int(platoColors.y) }
    var colorStride: Int { Int(platoColors.x) }

    init(_ device: MTLDevice) {

        self.plaTrii = PlaTrii([])
        self.device = device
        self.platoPhase = platoFlo.phase
        self.counter = PlatoCounter(8000, cameraFlo.stream, harmonic: 4)

        let sd = MTLSamplerDescriptor()
        sd.minFilter = .nearest
        sd.magFilter = .linear

        nextCounter()
    }

    func nextCounter() {

        if platoPhase != platoFlo.phase {

            platoPhase = platoFlo.phase
            counter.setPhase(platoPhase)
            counter.next()
            buildHarmonic()
            buildPhase()

        } else  if platoColors != platoFlo.colors {

            platoColors = platoFlo.colors
            counter.next()
            //?? buildHarmonic()
            //?? buildPhase()


        } else if platoFlo.morph {

            counter.next()

            if counter.newHarmonic {
                buildHarmonic()
            }
            if counter.newPhase {
                buildPhase()
            }
        }
    }
    func buildHarmonic() {
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
    func buildPhase() {
        logCounter()
        plaTrii = plaTriis[counter.phase]
        plaTrii.updateBuffers(device, counter, self)
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
