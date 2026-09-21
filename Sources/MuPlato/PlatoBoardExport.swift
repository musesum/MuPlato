// additive board-geometry export for PlaGo; no render-path changes

import Foundation
import simd

public struct PlatoTriCorners {
    public let triId: Int
    public let c0: [SIMD3<Float>] // 3 corners at range01 == 0
    public let c1: [SIMD3<Float>] // 3 corners at range01 == 1
}

public enum PlatoBoardExport {

    public static let phaseCount = 11

    /// standalone phase geometry at a subdivision level; triId is -1 (no render identity)
    public static func corners(phase: Int, level: Int = 0) -> [PlatoTriCorners] {
        guard (0 ..< phaseCount).contains(phase) else { return [] }
        let tris = PhaseTriangles.build(phase)
        _ = tris.trisect(level)
        return tris.triRanges.map {
            PlatoTriCorners(triId: -1,
                            c0: [$0.v0.p0, $0.v1.p0, $0.v2.p0],
                            c1: [$0.v0.p1, $0.v1.p1, $0.v2.p1])
        }
    }
}

public extension PlatoModel {
    /// live mesh triangles with render identity, for space-to-triangle mapping
    func exportTriangles() -> [PlatoTriCorners] {
        guard let phaseTriangles else { return [] }
        return phaseTriangles.triRanges.map {
            PlatoTriCorners(triId: $0.id,
                            c0: [$0.v0.p0, $0.v1.p0, $0.v2.p0],
                            c1: [$0.v0.p1, $0.v1.p1, $0.v2.p1])
        }
    }
}
