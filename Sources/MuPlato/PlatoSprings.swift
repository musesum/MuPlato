// created by musesum on 9/9/26

import simd
import Foundation

/// WinSky Shape port: vertices welded by position, pulled home by k1, held
/// to their edge lengths by k2, pushed out from the centroid by the balloon
/// pressure (Shape::addNormal, n = p − centroid), velocity averaged with the
/// neighbours (filterVelocity) and decayed by a drag that ramps once from
/// 0.7 to 0.99 (addVelocity); a touch (Shape::pick) thrusts the near
/// hemisphere toward the origin by 10^-d² of the touch strength. a constant
/// trim per vertex (updateTrim) rests the swollen ball on the built sphere
final class PlatoSprings {

    private(set) var slotOf = [Int]()          // vertex index -> slot
    private var home  = [SIMD3<Float>]()       // rest position this frame
    private var pos   = [SIMD3<Float>]()
    private var vel   = [SIMD3<Float>]()
    private var avg   = [SIMD3<Float>]()       // neighbourhood velocity
    private var count = [Int]()                // neighbour count
    private var slotNorm = [SIMD3<Float>]()
    private var faceNorm = [SIMD3<Float>]()    // per triangle
    private var edges = [(Int, Int)]()         // slot pairs
    private var tris  = [(Int, Int, Int)]()    // slot triples
    private var lerp0 = [SIMD3<Float>]()       // pos0 per slot
    private var lerp1 = [SIMD3<Float>]()       // pos1 per slot
    private var drag  = Float(0.7)
    private let dragFinal = Float(0.99)
    private var radius = Float(1)              // mean home radius: pick falloff scale
    private var area = Float(1)                // (mean edge / reference edge)²: pressure per vertex
    private var pending = [(at: SIMD3<Float>, factr: Float)]()
    private let lock = NSLock()
    private(set) var active = false            // energy left after the last step
    private(set) var energy = Float(0)         // Σ |v|² + |p − rest|² of the last step
    private let k1 = Float(0.005)              // home pull
    private let k2 = Float(0.6)                // edge spring
    private var trim = [SIMD3<Float>]()        // constant force: the pressed ball rests round
    private(set) var inflate = Float(1)        // rest radius over home radius under the balloon
    private var trimBalloon = Float.nan
    private var trimRange = Float.nan
    private var pristine = true                // not yet stepped: starts at its rest

    /// weld on the phase-start position only: vertices that share a corner
    /// but morph to different targets still share one spring slot, so the
    /// displacement never tears them apart
    static func weldKey(_ a: SIMD4<Float>) -> String {
        let q = Float(1e4)
        return "\(Int((a.x*q).rounded())),\(Int((a.y*q).rounded())),\(Int((a.z*q).rounded()))"
    }

    init(_ vertices: [PlatoVertex]) {
        var slotByKey = [String: Int]()
        slotOf.reserveCapacity(vertices.count)
        for v in vertices {
            let key = PlatoSprings.weldKey(v.pos0)
            if let slot = slotByKey[key] {
                slotOf.append(slot)
            } else {
                let slot = lerp0.count
                slotByKey[key] = slot
                slotOf.append(slot)
                lerp0.append(v.pos0.xyz)
                lerp1.append(v.pos1.xyz)
            }
        }
        let n = lerp0.count
        home = lerp0
        pos = lerp0
        vel = [SIMD3<Float>](repeating: .zero, count: n)
        avg = vel
        count = [Int](repeating: 0, count: n)
        slotNorm = vel
        trim = vel
        var seen = Set<Int>()
        for t in stride(from: 0, to: vertices.count - 2, by: 3) {
            let (a, b, c) = (slotOf[t], slotOf[t+1], slotOf[t+2])
            tris.append((a, b, c))
            for (p, q) in [(a, b), (b, c), (c, a)] where p != q {
                let key = p < q ? p << 20 | q : q << 20 | p
                if seen.insert(key).inserted { edges.append((p, q)) }
            }
        }
        faceNorm = [SIMD3<Float>](repeating: .zero, count: tris.count)
        for (a, b) in edges { count[a] += 1; count[b] += 1 }
        radius = max(0.1, home.reduce(0) { $0 + simd_length($1) } / Float(max(1, home.count)))
        // pressure is force per area: WinSky's constant was tuned on the
        // icosahedron subdivided three times (642 vertices), an edge of
        // 1.0515/8 of the radius. a finer mesh takes less per vertex and a
        // coarser one more, else the harmonic sets how far the ball inflates
        let meanEdge = edges.reduce(Float(0)) { $0 + simd_length(home[$1.1] - home[$1.0]) } / Float(max(1, edges.count))
        let refEdge = radius * 1.0515 / 8
        area = min(100, max(0.01, (meanEdge / refEdge) * (meanEdge / refEdge)))
        updateNormals()
    }

    /// face normals from the current positions, turned away from the
    /// centroid (the tables' winding is mixed), slot normals as their sum
    private func updateNormals() {
        for i in slotNorm.indices { slotNorm[i] = .zero }
        var centroid = SIMD3<Float>.zero
        for p in pos { centroid += p }
        centroid /= Float(max(1, pos.count))
        for (t, tri) in tris.enumerated() {
            var n = simd_cross(pos[tri.1] - pos[tri.0], pos[tri.2] - pos[tri.0])
            if simd_dot(n, pos[tri.0] + pos[tri.1] + pos[tri.2] - 3 * centroid) < 0 { n = -n }
            faceNorm[t] = n
            slotNorm[tri.0] += n
            slotNorm[tri.1] += n
            slotNorm[tri.2] += n
        }
        for i in slotNorm.indices {
            let l = simd_length(slotNorm[i])
            if l > 1e-9 { slotNorm[i] /= l }
        }
    }

    /// queue a Shape::pick thrust at the point where the sight ray met the
    /// object (PlatoNode+Hit), applied on the render thread's next step.
    /// 0.08 dents the round ball by a third to a half of its radius and
    /// rings down; at 0.15 a fine mesh caves in to the centre
    func impulse(at point: SIMD3<Float>, factr: Float = 0.08) {
        lock.lock(); pending.append((point, factr)); lock.unlock()
        active = true
    }

    /// every vertex is thrust toward the origin by 10^-d² of the distance
    /// from the hit point (d in mean radii)
    private func applyImpulses() {
        lock.lock(); let hits = pending; pending.removeAll(); lock.unlock()
        for hit in hits {
            for i in pos.indices {
                let d = simd_length_squared(pos[i] - hit.at) / (radius * radius)
                let s = 1 / pow(10, d)
                vel[i] -= pos[i] * s * hit.factr
            }
        }
    }

    /// one integration step; home follows the morph at range01;
    /// balloon 0…1 scales the outward pressure
    func step(balloon: Float, range01: Float) {
        applyImpulses()
        for i in home.indices {
            home[i] = lerp0[i] + (lerp1[i] - lerp0[i]) * range01
        }
        if trimBalloon != balloon || trimRange != range01 {
            updateTrim(balloon)
            trimBalloon = balloon
            trimRange = range01
        }
        // new springs start swollen to their rest, so a rebuild shows the
        // round ball at once instead of swelling into it
        if pristine {
            pristine = false
            for i in pos.indices { pos[i] = home[i] * inflate }
        }
        var centroid = SIMD3<Float>.zero
        for p in pos { centroid += p }
        centroid /= Float(max(1, pos.count))
        for i in home.indices {
            let radial = pos[i] - centroid
            let len = simd_length(radial)
            let out = len > 1e-6 ? radial / len : .zero
            vel[i] += (home[i] - pos[i]) * k1 + out * 0.005 * balloon * area + trim[i]
        }
        // WinSky's k2 at the icosahedral valence of 5–6; the centroid
        // subdivision here piles far more edges on the base corners, so a
        // vertex above valence 6 takes its share scaled down to that sum
        for (a, b) in edges {
            let rest = simd_length(home[b] - home[a])
            let f = pos[b] - pos[a]
            let len = simd_length(f)
            guard len > 1e-6 else { continue }
            let df = (f - f / len * rest) * k2
            vel[a] += df * min(1, 6 / Float(max(1, count[a])))
            vel[b] -= df * min(1, 6 / Float(max(1, count[b])))
        }
        for i in avg.indices { avg[i] = .zero }
        for (a, b) in edges {
            avg[a] += vel[b]; avg[b] += vel[a]
        }
        if drag < dragFinal { drag += 0.004 }
        energy = 0
        for i in pos.indices {
            if count[i] > 0 { vel[i] = vel[i] * 0.8 + avg[i] / Float(count[i]) * 0.2 }
            pos[i] += vel[i]
            vel[i] *= drag
            energy += simd_length_squared(vel[i]) + simd_length_squared(pos[i] - home[i] * inflate)
        }
        if !energy.isFinite { reset(); return }
        updateNormals()
        active = energy > 1e-7
    }

    /// the balloon swells the ball against its home pull and taut edges,
    /// and the mesh's mixed valence and edge lengths take the push
    /// unevenly: left alone it rests lumpy, a few percent out of round,
    /// and the vertex normals tilt with it. the ball's even size under
    /// the push is `inflate` times home, where the push outward and the
    /// pull back balance over the whole ball; each vertex is trimmed by
    /// the force left over there, so the sphere at that size is where
    /// it rests. the trim is constant: the edges stay as taut and a dent
    /// rings down as before, only to the sphere
    private func updateTrim(_ balloon: Float) {
        let n = home.count
        let pressure = 0.005 * balloon * area
        for i in trim.indices { trim[i] = .zero }
        inflate = 1
        guard n > 0, pressure != 0 else { return }
        var centroid = SIMD3<Float>.zero
        for h in home { centroid += h }
        centroid /= Float(n)
        // at pos = inflate · home each edge pulls (inflate − 1) · k2 · (hb − ha),
        // and home pulls (1 − inflate) · k1 · home: both scale with inflate − 1
        var pull = home.map { -$0 * k1 }
        for (a, b) in edges {
            let d = home[b] - home[a]
            guard simd_length(d) > 1e-6 else { continue }
            pull[a] += d * k2 * min(1, 6 / Float(max(1, count[a])))
            pull[b] -= d * k2 * min(1, 6 / Float(max(1, count[b])))
        }
        var outs = [SIMD3<Float>](repeating: .zero, count: n)
        var push = Float(0), back = Float(0)
        for i in 0 ..< n {
            let radial = home[i] - centroid
            let len = simd_length(radial)
            outs[i] = len > 1e-6 ? radial / len : .zero
            push += pressure * simd_length_squared(outs[i])
            back += simd_dot(pull[i], outs[i])
        }
        // a ball with no size to pull back on keeps the old push
        guard back < -1e-9 else { return }
        let swell = -push / back
        inflate = 1 + swell
        for i in 0 ..< n {
            trim[i] = -(pull[i] * swell + outs[i] * pressure)
        }
    }

    /// displacement from home for vertex index
    func offset(_ index: Int) -> SIMD3<Float> {
        let s = slotOf[index]
        return pos[s] - home[s]
    }
    /// unit vertex normal at the welded slot of vertex index; the shader
    /// makes the face normal itself from the three displaced corners and
    /// blends toward this one by norm.w. a sum that cancels falls back to
    /// the radial direction, shared by every corner of the slot
    func vertexNormal(_ index: Int) -> SIMD3<Float> {
        let s = slotOf[index]
        let n = slotNorm[s]
        if simd_length(n) > 1e-9 { return n }
        let p = pos[s]
        let l = simd_length(p)
        return l > 1e-9 ? p / l : SIMD3<Float>(0, 0, 1)
    }

    /// current position of vertex index: home plus its spring displacement
    func position(_ index: Int) -> SIMD3<Float> {
        return pos[slotOf[index]]
    }

    func reset() {
        lock.lock(); pending.removeAll(); lock.unlock()
        for i in pos.indices { pos[i] = home[i] * inflate }
        for i in vel.indices { vel[i] = .zero }
        active = false
        energy = 0
        updateNormals()
    }
}
