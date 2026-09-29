// created by musesum on 9/28/26

import Foundation
import simd

extension PlatoNode { // + Press

    /// the literal contact covers about one spring edge at any depth; the
    /// membrane spreads a finger's silhouette over six times its radius
    static let fingerSpread = Float(6)

    /// a canvas touch on the plato object in view points; radius is the
    /// finger silhouette in points, 0 for the pencil. phase 0 takes the
    /// touch when the sight ray meets the object while it shows: the stroke
    /// is muted and, with the spring on, the touch-down impulse fires as it
    /// always has and a held press starts there. 1 and 2 move and re-press
    /// it; 3 (ended or cancelled) lifts it
    public func press(_ id: Int,
                      _ point: CGPoint,
                      pressure: Float,
                      radius: Float,
                      phase: Int) -> Bool {
        switch phase {
        case 0:
            guard pipeFlo˚.val("on") ?? 0 > 0,
                  let hit = hitPoint(point) else { return false }
            if platoFlo.spring > 0 {
                platoMesh.model.springs?.impulse(at: hit)
            }
            setPress(id, point, pressure, radius, hit)
        case 3...:
            pressLock.withLock { presses[id] = nil }
        default:
            setPress(id, point, pressure, radius, nil)
        }
        return true
    }

    /// aim the press where the sight ray meets the rest sphere; a finger
    /// that slides off the ball keeps pressing its rim while the silhouette
    /// still overlaps it, then lets go until it slides back on
    private func setPress(_ id: Int,
                          _ point: CGPoint,
                          _ pressure: Float,
                          _ radius: Float,
                          _ hit: SIMD3<Float>?) {
        let r = pressLock.withLock { ballRadius }
        guard let ray = sightRay(point) else { return }
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
            return
        }
        // the silhouette at the wall it presses, which stays in front of an
        // eye zoomed inside the ball
        let foot = Self.fingerSpread * radius * perPoint * simd_length(dir * r - ray.eye)
        let press = SpringPress(id: id, dir: dir, pressure: pressure, foot: foot)
        pressLock.withLock { presses[id] = press }
    }
}
