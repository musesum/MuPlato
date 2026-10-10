// created by musesum on 9/28/26

import Foundation
import simd

extension PlatoNode { // + Press

    /// a canvas touch on the plato object in view points; radius is the
    /// finger silhouette in points, 0 for the pencil; time the touch's own
    /// clock, seconds. phase 0 takes the touch when the sight ray meets the
    /// object while it shows, and the stroke is muted. With the spring
    /// leaf's pressure on, the touch presses the vertices for as long as it
    /// is held, and a deep, fast landing drops an impulse on the way in
    /// (PressAttack), so a light touch only presses: the ico ball always, a
    /// platonic solid while the clock is off. Pressure off, it does nothing.
    /// 1 and 2 move and re-press it; 3 (ended or cancelled) lifts it
    public func press(_ id: Int,
                      _ point: CGPoint,
                      pressure: Float,
                      radius: Float,
                      phase: Int,
                      time: TimeInterval) -> Bool {
        let springs = platoFlo.deforms ? platoMesh.model.springs : nil
        switch phase {
        case 0:
            guard pipeFlo˚.val("on") ?? 0 > 0,
                  let hit = hitPoint(point) else { return false }
            guard platoFlo.pressure else { break }
            var attack = PressAttack(start: time)
            setPress(id, point, pressure, radius, hit)
            let factr = attack.factr(pressure: pressure, time: time)
            if factr > 0 { springs?.impulse(at: hit, factr: factr) }
            attacks[id] = attack
        case 3...:
            pressLock.withLock { presses[id] = nil }
            attacks[id] = nil
        default:
            // pressure turned off mid-touch lets go here, so turning it back
            // on presses where the touch is, not where it was
            guard platoFlo.pressure else {
                pressLock.withLock { presses[id] = nil }
                break
            }
            guard let at = setPress(id, point, pressure, radius, nil) else { break }
            // a landing that deepens within the attack window drops the rest
            if var attack = attacks[id] {
                let factr = attack.factr(pressure: pressure, time: time)
                attacks[id] = attack
                if factr > 0 { springs?.impulse(at: at, factr: factr) }
            }
        }
        return true
    }

    /// aim the press where the sight ray meets the rest sphere; a finger
    /// that slides off the ball keeps pressing its rim while the silhouette
    /// still overlaps it, then lets go until it slides back on. A platonic
    /// solid is no sphere, its face centres at half the corners' radius: the
    /// press aims where the ray meets its own faces at rest, and lets go off
    /// its edge. The press point at rest, or nil once it lets go
    @discardableResult
    private func setPress(_ id: Int,
                          _ point: CGPoint,
                          _ pressure: Float,
                          _ radius: Float,
                          _ hit: SIMD3<Float>?) -> SIMD3<Float>? {
        let r = pressLock.withLock { ballRadius }
        guard platoFlo.ico else {
            // a running clock leaves the solid be: no ray-cast per sample
            guard platoFlo.deforms,
                  let at = hitPoint(point, displaced: false) ?? hit,
                  simd_length(at) > 1e-6 else {
                pressLock.withLock { presses[id] = nil }
                return nil
            }
            let press = SpringPress(id: id, dir: simd_normalize(at), pressure: pressure,
                                    foot: SpringPress.footprint(silhouette: radius, ballRadius: r),
                                    spread: SpringPress.spread(cover: platoFlo.cover))
            pressLock.withLock { presses[id] = press }
            return at
        }
        guard let ray = sightRay(point) else { return nil }
        // the sight ray's turn per view point: times a distance, model units per point
        var perPoint = Float(0)
        if let ray2 = sightRay(CGPoint(x: point.x + 10, y: point.y)) {
            perPoint = simd_length(ray2.dir - ray.dir) / 10
        }
        // a miss is measured where the ray passes the rim, this far from the eye
        let rim = max(simd_length_squared(ray.eye) - r * r, 0).squareRoot()
        let reach = max(radius * perPoint * rim, 0.05 * r)
        var dir = r > 0 ? PlatoSprings.pressDirection(ray.eye, ray.dir, r, reach: reach) : nil
        if dir == nil, let hit, simd_length(hit) > 1e-6 {
            dir = simd_normalize(hit) // the ball's first frame, or an edge hit on a swollen lump
        }
        guard let dir else {
            pressLock.withLock { presses[id] = nil }
            return nil
        }
        // the spring leaf's disk spreads how much of the ball a touch covers
        let press = SpringPress(id: id, dir: dir, pressure: pressure,
                                foot: SpringPress.footprint(silhouette: radius, ballRadius: r),
                                spread: SpringPress.spread(cover: platoFlo.cover))
        pressLock.withLock { presses[id] = press }
        return r > 0 ? dir * r : hit
    }
}
