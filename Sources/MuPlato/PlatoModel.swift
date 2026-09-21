// created by musesum on 12/27/23

import MetalKit
import MuVision
import MuFlo

public class PlatoModel: MeshModel<PlatoVertex> {

    var phaseTriangles: PhaseTriangles!
    var platoPhases = [PhaseTriangles]()
    let platoFlo: PlatoFlo
    var counter: PlatoCounter!
    var phaseNow: Int
    var harmonicNow: Int
    var icoNow: Bool
    var convex = Float(0.95)
    var smooth = Float(0)
    var springs: PlatoSprings?

    init(_ platoFlo: PlatoFlo,
         _ nameFormats: [VertexNameFormat],
         _ vertexStride: Int) {

        self.platoFlo = platoFlo
        // seed from the flo so the first nextCounter() sees no edit and skips a
        // redundant full rebuild
        self.phaseNow = platoFlo.phase
        self.harmonicNow = platoFlo.harmonic
        self.icoNow = platoFlo.ico
        super.init(nameFormats, vertexStride)
        let steps = 200 //CameraFlos.shared.stream ? 120 : 200

        self.counter = PlatoCounter(platoFlo, steps: steps,
                                    phase: platoFlo.phase,
                                    harmonic: platoFlo.harmonic)
        buildHarmonic()
        buildPhase()
    }
    func updatePlatoBuffers() {
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

        // the ball is round only once subdivided, and 4^h grows past 3^h
        // while the springs step every vertex on the cpu each frame: the
        // ico depth holds to 2…4 and backs off where a phase would pass
        // 16k triangles (the 120-face dodeca phases stop at 3)
        for phaseIndex in 0 ..< platoPhases.count {
            let phase = platoPhases[phaseIndex]
            if platoFlo.ico {
                var icoDepth = min(max(counter.harmonic, 2), 4)
                while icoDepth > 2, phase.triRanges.count << (2 * icoDepth) > 16384 {
                    icoDepth -= 1
                }
                // round ball: corners on the circumsphere, then geodesic midpoints
                phase.spherize()
                _ = phase.quadsect(icoDepth)
            } else {
                _ = phase.trisect(counter.harmonic)
            }
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
        let convexEdit = convex != platoFlo.convex
        if convexEdit || smooth != platoFlo.normal {
            convex = platoFlo.convex
            smooth = platoFlo.normal
            // the normal slider moves no vertex: keep the springs so a
            // dent or ring-down survives dragging it
            buildPhase(keepSprings: !convexEdit)
            return true
        }
        return false
    }
    func nextCounter() -> Bool {

        var changed = false
        let phaseEdit    = phaseNow    != platoFlo.phase
        let harmonicEdit = harmonicNow != platoFlo.harmonic
        let icoEdit      = icoNow      != platoFlo.ico

        if phaseEdit || harmonicEdit || icoEdit {

            phaseNow = platoFlo.phase
            harmonicNow = platoFlo.harmonic
            icoNow = platoFlo.ico

            // the ball holds still at the head of the phase the sweep was in:
            // range01 0 is a whole geodesic sphere, a mid-morph lerp is a
            // chord-dented one. off resumes the sweep from that head
            if icoEdit, icoNow {
                counter.setPhase(counter.phase)
            }
            // the running sweep never writes its phase back to the flo, so
            // re-anchoring on a harmonic edit would yank the sweep to a stale
            // phase. each edit moves only what it names
            if harmonicEdit {
                counter.setHarmonic(harmonicNow)
                buildHarmonic()
            } else if icoEdit {
                buildHarmonic()
            }
            if phaseEdit {
                counter.setPhase(phaseNow)
            }
            buildPhase()
            changed = true

        } else if platoFlo.run, !platoFlo.ico { // ico holds its mesh: no phase sweep

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
    func buildPhase(keepSprings: Bool = false) {
        counter.newPhase = false
        phaseTriangles = platoPhases[counter.phase]
        // convex^harmonic pulls the subdivided rings inside the corner
        // sphere, which is the spikiness the ball must not have
        let convex = platoFlo.ico ? 1 : platoFlo.convex
        phaseTriangles.updateTriangles(convex, counter.phase, smooth: platoFlo.normal)

        vertices = phaseTriangles.vertices
        indices = phaseTriangles.indices
        updatePlatoBuffers()
        // fresh springs rest on the vertices just built: no offset or
        // velocity survives a rebuild, so an ico off → on cycle starts still
        if !keepSprings || springs?.slotOf.count != vertices.count {
            springs = PlatoSprings(vertices)
        }
        //counter.logCountNow()
    }

}
