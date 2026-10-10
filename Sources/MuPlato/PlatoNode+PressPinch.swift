// created by musesum on 9/29/26

#if os(visionOS)
import Foundation
import simd
import MuFlo
import MuVision

extension PlatoNode { // + PressPinch

    typealias PinchRay = (eye: SIMD3<Float>, dir: SIMD3<Float>)

    /// where a pinch began: its model-space point, the sight ray through it,
    /// and whether it began inside the solid; the hand task alone touches it
    private struct PinchStart {
        let at: SIMD3<Float>
        let dir: SIMD3<Float>
        let inside: Bool
    }
    nonisolated(unsafe) private static var starts = [Int: PinchStart]()

    /// a pinch on visionOS as `press` takes a canvas touch. The sight ray
    /// runs from the head through the pinch, both in model space through the
    /// eye buffer's last placement. Pressure is the pinch's travel since it
    /// began, along that first ray, over the press depth: the tip follows
    /// the hand, so a small move is a small dent. A pinch that began inside
    /// the solid aims at the wall ahead of it and lifts it outward; one from
    /// outside aims where the sight ray lands and sinks it. The tip is the
    /// pencil's, no silhouette. Phases as `press`: 0 takes the pinch when
    /// the aim meets the object while it shows; 1 and 2 re-press; 3 lifts
    public func pressPinch(_ id: Int,
                           at pinch: SIMD3<Float>,
                           phase: Int,
                           time: TimeInterval) -> Bool {
        let springs = platoFlo.deforms ? platoMesh.model.springs : nil
        switch phase {
        case 0:
            guard pipeFlo˚.val("on") ?? 0 > 0,
                  let (ray, at) = pinchRay(pinch) else { return false }
            let inside = isInside(at)
            let aim: PinchRay = inside ? (at, ray.dir) : ray
            guard let hit = hitPoint(aim) else { return false }
            Self.starts[id] = PinchStart(at: at, dir: ray.dir, inside: inside)
            guard platoFlo.pressure else { break }
            // no travel yet: the tip rests on the surface until the hand moves
            setPinch(id, aim, 0, inside, hit)
            attacks[id] = PressAttack(start: time)
        case 3...:
            pressLock.withLock { presses[id] = nil }
            attacks[id] = nil
            Self.starts[id] = nil
        default:
            guard platoFlo.pressure else {
                pressLock.withLock { presses[id] = nil }
                break
            }
            guard let start = Self.starts[id],
                  let (ray, at) = pinchRay(pinch) else { break }
            let pressure = travel(at, start)
            let aim: PinchRay = start.inside ? (at, ray.dir) : ray
            guard let hitAt = setPinch(id, aim, pressure, start.inside, nil) else { break }
            if var attack = attacks[id] {
                let factr = attack.factr(pressure: pressure, time: time)
                attacks[id] = attack
                if factr > 0 { springs?.impulse(at: hitAt, factr: factr) }
            }
        }
        return true
    }

    /// the pinch in model space, with the sight ray from the head through it
    private func pinchRay(_ pinch: SIMD3<Float>) -> (PinchRay, SIMD3<Float>)? {
        guard let eyeBuf = platoMesh.eyeBuf else { return nil }
        let toModel = eyeBuf.visionModel.inverse
        let eye = (toModel * SIMD4<Float>(eyeBuf.visionHead, 1)).xyz
        let at = (toModel * SIMD4<Float>(pinch, 1)).xyz
        let d = at - eye
        guard simd_length_squared(d) > 1e-12 else { return nil }
        return ((eye, simd_normalize(d)), at)
    }

    /// the pinch's travel since it began along its first ray, as a share of
    /// the press depth: pressure 1 sinks the tip as far as the hand moved
    private func travel(_ at: SIMD3<Float>, _ start: PinchStart) -> Float {
        let r = pressLock.withLock { ballRadius }
        let depth = min(max(platoFlo.press, 0), PlatoSprings.depthMax) * r
        guard depth > 1e-6 else { return 0 }
        return min(max(simd_dot(at - start.at, start.dir) / depth, 0), 1)
    }

    /// the point is inside the solid at rest: an odd count of crossings of
    /// the rest mesh along a ray out of it
    private func isInside(_ p: SIMD3<Float>) -> Bool {
        let model = platoMesh.model!
        let vertices = model.vertices!
        let range01 = model.counter.range01
        // off every axis and mirror plane, so the ray clears the mesh's edges
        let dir = simd_normalize(SIMD3<Float>(0.3123, 0.5471, 0.7789))
        let corner: (Int) -> SIMD3<Float> = { i in
            let v = vertices[i]
            return v.pos0.xyz + (v.pos1.xyz - v.pos0.xyz) * range01
        }
        var origin = p
        var crossings = 0
        while crossings < 64, let hit = Self.nearestHit(origin, dir, vertices.count, corner) {
            crossings += 1
            origin = hit + dir * 1e-4
        }
        return crossings % 2 == 1
    }

    /// nearest point where the ray crosses a triangle of the mesh as drawn
    /// this frame, or at rest under a dent (PlatoNode+Hit.hitPoint by ray)
    private func hitPoint(_ ray: PinchRay, displaced: Bool = true) -> SIMD3<Float>? {
        let model = platoMesh.model!
        let vertices = model.vertices!
        let range01 = model.counter.range01
        let springs = displaced && platoMesh.springsWritten ? model.springs : nil
        return Self.nearestHit(ray.eye, ray.dir, vertices.count) { i in
            let v = vertices[i]
            let p = v.pos0.xyz + (v.pos1.xyz - v.pos0.xyz) * range01
            return p + (springs?.offset(i) ?? .zero)
        }
    }

    /// setPress by ray: the ball takes the ray's first meeting with the rest
    /// sphere, a miss within the pencil's reach slides to the rim; a solid
    /// takes the ray's meeting with its faces at rest. The press point at
    /// rest, or nil once it lets go
    @discardableResult
    private func setPinch(_ id: Int,
                          _ ray: PinchRay,
                          _ pressure: Float,
                          _ outward: Bool,
                          _ hit: SIMD3<Float>?) -> SIMD3<Float>? {
        let r = pressLock.withLock { ballRadius }
        let foot = SpringPress.footprint(silhouette: 0, ballRadius: r)
        let spread = SpringPress.spread(cover: platoFlo.cover)
        guard platoFlo.ico else {
            guard platoFlo.deforms,
                  let at = hitPoint(ray, displaced: false) ?? hit,
                  simd_length(at) > 1e-6 else {
                pressLock.withLock { presses[id] = nil }
                return nil
            }
            let press = SpringPress(id: id, dir: simd_normalize(at), pressure: pressure,
                                    foot: foot, spread: spread, outward: outward)
            pressLock.withLock { presses[id] = press }
            return at
        }
        var dir = r > 0 ? PlatoSprings.pressDirection(ray.eye, ray.dir, r, reach: 0.05 * r) : nil
        if dir == nil, let hit, simd_length(hit) > 1e-6 {
            dir = simd_normalize(hit) // the ball's first frame, or an edge hit on a swollen lump
        }
        guard let dir else {
            pressLock.withLock { presses[id] = nil }
            return nil
        }
        let press = SpringPress(id: id, dir: dir, pressure: pressure,
                                foot: foot, spread: spread, outward: outward)
        pressLock.withLock { presses[id] = press }
        return r > 0 ? dir * r : hit
    }
}
#endif
