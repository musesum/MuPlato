// Platonic.swift

import Foundation
import Collections
import Vision
import UIKit

open class Platonic {

    var counter: PlatoCounter
    var platoTris: PlatoTris
    var platoTriss = [PlatoTris]()

    var device: MTLDevice 

    //var harmonicSteps = 1000

    let platoFlo = PlatoFlo.shared
    let cameraFlo = CameraFlo.shared
    var platoPhase = CGPoint.zero

    init(_ device: MTLDevice) {

        self.platoTris = PlatoTris([])
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

        for phase in 0 ..< platoTriss.count {
            let plaTrii = platoTriss[phase]
            _ = plaTrii.trisect(counter.harmonic)
        }
        for i in 0 ..< platoTriss.count {

            let plaTrii = platoTriss[i]

            logBuildCounter(i)
            for tri in plaTrii.tri01s {
                tri.setId(i)
            }
        }
    }
    func buildPhase() {
        logCounter()
        platoTris = platoTriss[counter.phase]
        platoTris.updateBuffers(device)
    }
    func logBuildCounter(_ i: Int) {
        //print("build phase: \(i) harmonic: \(counter.harmonic )")
    }
    func logCounter() {
        print("phase: \(counter.phase)  harmonic: \(counter.harmonic) counter: \(counter.counter)  \(counter.increasing ? ">" : "<")")
    }
    func updateHarmonif(_ harmonif: Float) {
        platoTris.updateHarmonif(harmonif, device)
        
    }
    func ranges() -> vector_float4 {
        return vector_float4(counter.range01,
                             Float(platoFlo.phase.y), // harmonif
                             Float(platoFlo.colors.x),
                             Float(platoFlo.colors.y))
    }
    func shadow() -> vector_float4 {
        return vector_float4(Float(platoFlo.shadow.x),
                             Float(platoFlo.shadow.y),
                             Float(platoFlo.invert),
                             Float(platoFlo.zoom))
    }
}
