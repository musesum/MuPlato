// created by musesum on 9/9/26

import simd
import Foundation

/// a held touch on the ball: a round rigid tip sunk toward the centre
struct SpringPress {
    let id: Int
    let dir: SIMD3<Float>   // unit: centre → the press on the rest sphere
    let pressure: Float     // 0…1
    let foot: Float         // footprint radius, model units; 0 is the narrowest
    /// the spring leaf's disk: how many times its own width the press
    /// covers once the mesh has clamped it (PlatoSprings.applyPresses)
    var spread = Float(1)
    /// a press from inside the solid lifts its surface out instead of
    /// sinking it: the visionOS thumb-middle pinch begun inside. A touch on
    /// the glass always presses in
    var outward = false

    /// a light fingertip's silhouette, points (TouchPress.fingerLight)
    static let lightFinger = Float(21)
    /// the disk's default, where a press is as wide as the mesh allows
    /// its touch: spread 1
    static let coverDefault = Float(0.4)

    /// the footprint a touch covers at the disk's default, model units:
    /// 0.4 of half the ball, a finger widened by its silhouette (a light
    /// fingertip ×1, a flatter one up to ×2) and the pencil's tip half a
    /// fingertip's
    static func footprint(silhouette: Float, ballRadius: Float) -> Float {
        let widen = silhouette > 0 ? min(max(silhouette / lightFinger, 1), 2) : 0.5
        return coverDefault * 0.5 * max(ballRadius, 0) * widen
    }
    /// the disk's cover 0…1 as a spread: 0.2 at 0, 1 at the default, 2.2 at 1
    static func spread(cover: Float) -> Float {
        (0.1 + min(max(cover, 0), 1)) / (0.1 + coverDefault)
    }
}

/// the impulse a touch drops as it lands. For `window` seconds after touch
/// down each rise of smoothstep(low, 1, pressure) fires its share of the
/// whole tap (0.08); nothing after. A light touch fires nothing and only
/// presses, a deep fast one fires the whole tap, and a slow firm press
/// sinks all the way without one
struct PressAttack {

    static let window = TimeInterval(0.10) // 6 frames at 60 Hz, 12 at 120
    static let low    = Float(0.3)         // a light fingertip (0.25) is under it
    static let whole  = Float(0.08)        // the single tap's thrust

    let start: TimeInterval
    private(set) var fired = Float(0)

    init(start: TimeInterval) { self.start = start }

    static func weight(_ pressure: Float) -> Float {
        let t = min(max((pressure - low) / (1 - low), 0), 1)
        return t * t * (3 - 2 * t)
    }
    /// the thrust this sample adds; 0 once the window has closed or when
    /// the pressure has not risen past what already fired
    mutating func factr(pressure: Float, time: TimeInterval) -> Float {
        guard time - start < Self.window else { return 0 }
        let w = Self.weight(pressure)
        guard w > fired else { return 0 }
        let thrust = Self.whole * (w - fired)
        fired = w
        return thrust
    }
}

/// WinSky Shape port: vertices welded by position, pulled home by k1, held
/// to their edge lengths by k2, pushed out from the centroid by the balloon
/// pressure (Shape::addNormal, n = p − centroid), velocity averaged with the
/// neighbours (filterVelocity) and decayed by a drag that ramps once from
/// 0.7 to 0.99 (addVelocity); a deep, fast touch (Shape::pick, sized by
/// PressAttack) thrusts the near hemisphere toward the origin by 10^-d² of
/// the touch strength. a constant
/// trim per vertex (updateTrim) rests the swollen ball on the built sphere.
/// a held touch sinks a rigid round tip into the ball as deep as its
/// pressure (applyPresses); the springs push back against it and ring down
/// once it lifts. A platonic solid takes the same touch with no balloon and
/// a stronger home pull (HomePull.solid)
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
    private let k1: Float                      // home pull: homePull.ball or .solid
    private let k2 = Float(0.6)                // edge spring
    private var trim = [SIMD3<Float>]()        // constant force: the pressed ball rests round
    private(set) var inflate = Float(1)        // rest radius over home radius under the balloon
    private var trimBalloon = Float.nan
    private var trimRange = Float.nan
    private var pristine = true                // not yet stepped: starts at its rest
    let solid: Bool                            // a platonic solid: no normals of its own
    let builtAt: Float                         // the range01 a solid's slots were welded and sized at
    private(set) var meanEdge = Float(0)       // mean home edge length
    private var tipDepth = [Int: Float]()      // press id -> eased tip depth, model units
    private var indent = [Float]()             // per slot: how far the tips sink its rest, < 0 lifts it
    private(set) var pushBack = Float(0)       // Σ how far the tips set slots back or out, last step
    var restRadius: Float { radius * inflate }

    static let tipEase   = Float(0.3) // a tip moves this share of the way each step: 90% in 7
    static let footEdges = Float(2)   // narrowest footprint, mean edges: a face-centred press keeps its depth
    static let footMax   = Float(0.5) // widest, ball radii; wins over footEdges on a coarse ball
    static let footLow   = Float(0.25) // the disk's narrowest on a coarse ball, ball radii: a pinch at a vertex
    static let footWide  = Float(0.6)  // the disk's widest, ball radii: 0.8 overshoots a third and folds the default ball
    static let slopeMax  = Float(3)   // tip depth ≤ 3 footprints, else a narrow press folds the mesh for good
    static let depthMax  = Float(0.8) // press slider ceiling, ball radii: the lowest surface stays ≥ 0.15
    static let ownShare  = Float(0.85) // a slot sinks at most this share of its own rest radius: a solid's face centres sit at 0.56 R

    /// WinSky's home pull holds the round ball, whose balloon pushes a dent
    /// back out; a platonic solid has no balloon, and at that pull a pressed
    /// patch of a flat face snaps through and stays (1 in 6 presses across
    /// phases 1…10, subdiv 0…3). Twenty times the pull brings every one home
    enum HomePull {
        static let ball  = Float(0.005)
        static let solid = Float(0.1)
    }

    /// weld on the phase-start position only: vertices that share a corner
    /// but morph to different targets still share one spring slot, so the
    /// displacement never tears them apart
    static func weldKey(_ a: SIMD4<Float>) -> String {
        let q = Float(1e4)
        return "\(Int((a.x*q).rounded())),\(Int((a.y*q).rounded())),\(Int((a.z*q).rounded()))"
    }

    /// solid: a platonic solid, welded and sized where the clock left its
    /// morph, at range01. Its points part as the morph runs -- phase 0 grows
    /// its tetra out of one point, phase 1 spreads a face's centre off its
    /// corner -- so a weld on the start would make them one spring, press
    /// the protruding point from its corner's direction and size phase 0
    /// as a point. The ball welds on the start, as it always has
    init(_ vertices: [PlatoVertex], homePull: Float = HomePull.ball,
         solid: Bool = false, at range01: Float = 0) {
        k1 = homePull
        self.solid = solid
        builtAt = solid ? range01 : 0
        let r = builtAt
        var slotByKey = [String: Int]()
        slotOf.reserveCapacity(vertices.count)
        for v in vertices {
            let key = PlatoSprings.weldKey(solid ? v.pos0 + (v.pos1 - v.pos0) * r : v.pos0)
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
        for i in home.indices where r != 0 { home[i] = lerp0[i] + (lerp1[i] - lerp0[i]) * r }
        pos = home
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
        meanEdge = edges.reduce(Float(0)) { $0 + simd_length(home[$1.1] - home[$1.0]) } / Float(max(1, edges.count))
        let refEdge = radius * 1.0515 / 8
        area = min(100, max(0.01, (meanEdge / refEdge) * (meanEdge / refEdge)))
        updateNormals()
    }

    /// face normals from the current positions, turned away from the
    /// centroid (the tables' winding is mixed), slot normals as their sum
    private func updateNormals() {
        guard !solid else { return } // a solid keeps its built normals (PlatoMesh)
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
    /// 0.08 dents the ball 0.13 of its radius on the 34-spring default
    /// (phase 1, subdiv 0) up to 0.91 on phase 10 subdiv 3, and rings
    /// down; at 0.15 a fine mesh caves in to the centre
    func impulse(at point: SIMD3<Float>, factr: Float = 0.08) {
        lock.lock(); pending.append((point, factr)); lock.unlock()
        active = true
    }

    /// the thrusts a touch queued on springs that were rebuilt before they
    /// stepped: a deep, fast landing on a solid the clock just left
    func adopt(_ other: PlatoSprings) {
        other.lock.lock(); let hits = other.pending; other.pending.removeAll(); other.lock.unlock()
        guard !hits.isEmpty else { return }
        lock.lock(); pending += hits; lock.unlock()
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
    /// balloon 0…1 scales the outward pressure; each held press sinks a tip
    /// up to pressure × pressDepth ball radii
    func step(balloon: Float, range01: Float,
              presses: [SpringPress] = [], pressDepth: Float = 0) {
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
        let pressing = applyPresses(presses, pressDepth)
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
            if pressing, indent[i] != 0 { contact(i) }
            vel[i] *= drag
            energy += simd_length_squared(vel[i]) + simd_length_squared(pos[i] - home[i] * inflate)
        }
        if !energy.isFinite { reset(); return }
        updateNormals()
        active = energy > 1e-7
    }

    /// ease each tip toward pressure × depth radii and sink every slot's
    /// rest under it by exp(−q²), q = chord on the rest sphere / footprint,
    /// or lift it by as much for an outward press; touches take the tip
    /// that moves the slot furthest, never the sum. false leaves the step
    /// as it was before presses, bit for bit
    private func applyPresses(_ presses: [SpringPress], _ pressDepth: Float) -> Bool {
        pushBack = 0
        if !tipDepth.isEmpty {
            let ids = Set(presses.map(\.id))
            tipDepth = tipDepth.filter { ids.contains($0.key) }
        }
        guard !presses.isEmpty else { return false }
        let R = restRadius
        let depth = min(max(pressDepth, 0), Self.depthMax)
        var tips = [(dir: SIMD3<Float>, sink: Float, foot: Float)]()
        for p in presses {
            // the mesh's width for the touch, then the disk's spread of it:
            // on the default ball 2 edges pass footMax, so without the
            // spread every cover would press the same 0.5 R
            let edges = Self.footEdges * meanEdge * inflate
            let fits = min(max(p.foot, edges), Self.footMax * R)
            let foot = min(max(fits * p.spread, min(edges, Self.footLow * R)), Self.footWide * R)
            let target = min(min(max(p.pressure, 0), 1) * depth * R, Self.slopeMax * foot)
            let was = tipDepth[p.id] ?? 0
            let sink = was + (target - was) * Self.tipEase
            tipDepth[p.id] = sink
            if sink > 1e-6 * R { tips.append((p.dir, p.outward ? -sink : sink, foot)) }
        }
        guard !tips.isEmpty else { return false }
        if indent.count != pos.count { indent = [Float](repeating: 0, count: pos.count) }
        for i in pos.indices {
            let rest = home[i] * inflate
            let rr = simd_length(rest)
            var sink = Float(0)
            if rr > 1e-6 {
                for t in tips {
                    let q = simd_length(rest / rr - t.dir) * rr / t.foot
                    // all inward, this is max(sink, s), as before outward
                    if q < 3, case let s = t.sink * exp(-q * q), abs(s) > abs(sink) { sink = s }
                }
            }
            // in, a slot keeps the rest of its own radius; out, as far again
            indent[i] = sink >= 0 ? min(sink, Self.ownShare * rr) : max(sink, -Self.ownShare * rr)
        }
        return true
    }

    /// the tip is rigid: a slot outside it is set back onto it and loses
    /// its outward speed; inward it moves freely. An outward tip holds a
    /// slot on it both ways, a pinch's grip: the ball's balloon pushes the
    /// same way as the lift, and a tip under the slot alone let it float
    /// 20–50% past the hand
    private func contact(_ i: Int) {
        let rest = home[i] * inflate
        let rr = simd_length(rest)
        let rhat = rest / rr
        if indent[i] < 0 {
            let off = (rr - indent[i]) - simd_dot(pos[i], rhat)
            pos[i] += rhat * off
            pushBack += abs(off)
            vel[i] -= rhat * simd_dot(vel[i], rhat)
            return
        }
        let over = simd_dot(pos[i], rhat) - (rr - indent[i])
        guard over > 0 else { return }
        pos[i] -= rhat * over
        pushBack += over
        let out = simd_dot(vel[i], rhat)
        if out > 0 { vel[i] -= rhat * out }
    }

    /// unit direction from the centre to where a sight ray first meets the
    /// sphere of radius r; an eye inside takes the wall ahead. a miss within
    /// reach of the sphere slides to the rim (the ray's closest approach);
    /// a wider miss, or a sphere behind the eye, is nil
    static func pressDirection(_ eye: SIMD3<Float>,
                               _ dir: SIMD3<Float>,
                               _ r: Float,
                               reach: Float = 0) -> SIMD3<Float>? {
        let b = simd_dot(eye, dir)
        let disc = b * b - (simd_length_squared(eye) - r * r)
        var t = -b // closest approach
        if disc >= 0 {
            let root = disc.squareRoot()
            t = -b - root > 0 ? -b - root : -b + root
        } else if simd_length(eye + dir * t) - r > reach {
            return nil
        }
        guard t > 0 else { return nil }
        let p = eye + dir * t
        let l = simd_length(p)
        return l > 1e-6 ? p / l : nil
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
        tipDepth.removeAll()
        pushBack = 0
        active = false
        energy = 0
        updateNormals()
    }
}
