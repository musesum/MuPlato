// created by musesum on 9/9/26

import Foundation
import simd
import MuVision

extension PlatoNode { // + Hit

    /// sight ray in model space from a view point, through the last
    /// projection: (eye, unit direction)
    func sightRay(_ point: CGPoint) -> (eye: SIMD3<Float>, dir: SIMD3<Float>)? {
        guard let eyeBuf = platoMesh.eyeBuf else { return nil }
        let size = pipeline.layer.drawableSize
        let scale = pipeline.layer.contentsScale
        guard size.width > 0, size.height > 0 else { return nil }
        let nx = Float(point.x * scale / size.width) * 2 - 1
        let ny = 1 - Float(point.y * scale / size.height) * 2
        let invProj = eyeBuf.projection.inverse
        let invView = eyeBuf.viewModel.inverse
        func unproject(_ z: Float) -> SIMD3<Float> {
            let v = invProj * SIMD4<Float>(nx, ny, z, 1)
            let p = SIMD4<Float>(v.x / v.w, v.y / v.w, v.z / v.w, 1)
            return (invView * p).xyz
        }
        let near = unproject(0)
        let far = unproject(1)
        let eye = (invView * SIMD4<Float>(0, 0, 0, 1)).xyz
        let d = far - near
        guard simd_length_squared(d) > 1e-12 else { return nil }
        return (eye, simd_normalize(d))
    }

    /// nearest point where the sight ray crosses a triangle of the mesh as
    /// drawn this frame: pos0…pos1 at range01 plus the spring offset, or
    /// without it, the solid at rest under a dent
    func hitPoint(_ point: CGPoint, displaced: Bool = true) -> SIMD3<Float>? {
        guard let ray = sightRay(point) else { return nil }
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

    /// nearest point where a ray crosses a triangle of `count` corners, three
    /// per triangle, each corner where `at` puts it
    static func nearestHit(_ eye: SIMD3<Float>, _ dir: SIMD3<Float>, _ count: Int,
                           _ at: (Int) -> SIMD3<Float>) -> SIMD3<Float>? {
        var nearest = Float.greatestFiniteMagnitude
        var hit: SIMD3<Float>?
        for t in stride(from: 0, to: count - 2, by: 3) {
            if let s = rayTriangle(eye, dir, at(t), at(t+1), at(t+2)), s < nearest {
                nearest = s
                hit = eye + dir * s
            }
        }
        return hit
    }

    /// Möller–Trumbore, both windings; distance along the ray or nil
    private static func rayTriangle(_ o: SIMD3<Float>, _ d: SIMD3<Float>,
                             _ a: SIMD3<Float>, _ b: SIMD3<Float>, _ c: SIMD3<Float>) -> Float? {
        let e1 = b - a
        let e2 = c - a
        let p = simd_cross(d, e2)
        let det = simd_dot(e1, p)
        guard abs(det) > 1e-9 else { return nil }
        let inv = 1 / det
        let s = o - a
        let u = simd_dot(s, p) * inv
        guard u >= 0, u <= 1 else { return nil }
        let q = simd_cross(s, e1)
        let v = simd_dot(d, q) * inv
        guard v >= 0, u + v <= 1 else { return nil }
        let t = simd_dot(e2, q) * inv
        return t > 1e-6 ? t : nil
    }
}
