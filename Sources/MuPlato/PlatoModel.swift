// created by musesum on 12/27/23

import MetalKit
import MuVision

public class PlatoModel: MeshModel<PlatoVertex> {

    var phaseTriangles: PhaseTriangles!
    var platoPhases = [PhaseTriangles]()
    let platoFlo   = PlatoFlo.shared
    let cameraFlo = CameraFlo.shared
    var counter: PlatoCounter!
    var phaseNow = 0
    var harmonicNow = 0
    var convex = Float(0.95)

    override public init(_ device: MTLDevice,
                         _ nameFormats: [VertexNameFormat],
                         _ vertexStride: Int) {

        super.init(device, nameFormats, vertexStride)
        let steps =  cameraFlo.stream ? 120 : 200
        self.counter = PlatoCounter(steps: steps, phase: 1, harmonic: 1)
        buildHarmonic()
        buildPhase()
    }
    func updatePlatoBuffers() {
        //???? let triCount = phaseTriangles.triCount
        let verticesLen = vertices.count * MemoryLayout<PlatoVertex>.stride
        let indicesLen  = indices.count * MemoryLayout<UInt32>.size
        updateBuffers(verticesLen, indicesLen)
    }

    func buildHarmonic() {
        counter.newHarmonic = false
        TriRange.reset()
        // buildAll
        platoPhases.removeAll()
        for phase in 0 ..< counter.phases {
            platoPhases.append(PhaseTriangles.build(phase))
        }

        for phaseIndex in 0 ..< platoPhases.count {
            let phase = platoPhases[phaseIndex]
            _ = phase.trisect(counter.harmonic)
        }
        for phaseIndex in 0 ..< platoPhases.count {
            let phase = platoPhases[phaseIndex]
            logBuildCounter(phaseIndex)
            for tri in phase.triRanges {
                tri.setId(phaseIndex)
            }
        }
        func logBuildCounter(_ i: Int) {
            //print("build phase: \(i) harmonic: \(counter.harmonic )")
        }
    }
    func updateConvex() -> Bool {
        if convex != platoFlo.convex {
            convex = platoFlo.convex
            return true
        }
        return false
    }
    func nextCounter() -> Bool {

        var changed = false

        if phaseNow != platoFlo.phase ||
            harmonicNow != platoFlo.harmonic
        {
            phaseNow = platoFlo.phase
            harmonicNow = platoFlo.harmonic
            counter.setPhaseHarmonic(phaseNow,harmonicNow)
            buildHarmonic()
            buildPhase()
            changed = true

        } else if platoFlo.run {

            counter.next()

            if counter.newHarmonic {
                buildHarmonic()
                changed = true
            }
            if counter.newPhase {
                buildPhase()
                changed = true
            }
        }
        return changed 
    }
    func buildPhase() {
        counter.newPhase = false
        phaseTriangles = platoPhases[counter.phase]
        phaseTriangles.updateTriangles(counter.phase)

        vertices = phaseTriangles.vertices
        indices = phaseTriangles.indices
        updatePlatoBuffers()
        counter.logCountNow()
    }

}
