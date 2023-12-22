// Platonic.swift

import Foundation
import Collections
import Vision
import UIKit

open class Platonic {

    let device: MTLDevice
    let metalVD: MTLVertexDescriptor

    var counter: PlatoCounter
    var platoModel: PlatoModel!
    var platoModels = [PlatoModel]()
    
    //var harmonicSteps = 1000

    let platoFlo = PlatoFlo.shared
    let cameraFlo = CameraFlo.shared
    var platoPhase = CGPoint.zero

    public init(_ device: MTLDevice,
                _ metalVD: MTLVertexDescriptor) {

        self.device = device
        self.metalVD = metalVD
        //???? self.platoModel = PlatoModel([])
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

        for phase in 0 ..< platoModels.count {
            let plaTrii = platoModels[phase]
            _ = plaTrii.trisect(counter.harmonic)
        }
        for i in 0 ..< platoModels.count {

            let plaTrii = platoModels[i]

            logBuildCounter(i)
            for tri in plaTrii.tri01s {
                tri.setId(i)
            }
        }
    }
    func buildPhase() {
        logCounter()
        platoModel = platoModels[counter.phase]
        platoModel.updateBuffers(device)
    }
    func logBuildCounter(_ i: Int) {
        //print("build phase: \(i) harmonic: \(counter.harmonic )")
    }
    func logCounter() {
        print("phase: \(counter.phase)  harmonic: \(counter.harmonic) counter: \(counter.counter)  \(counter.increasing ? ">" : "<")")
    }
    func updateHarmonif(_ harmonif: Float) {
        platoModel.updateHarmonif(harmonif, device)
        
    }
    func shadow() -> vector_float4 {
        return vector_float4(Float(platoFlo.shadow.x),
                             Float(platoFlo.shadow.y),
                             Float(platoFlo.invert),
                             Float(platoFlo.zoom))
    }
}
