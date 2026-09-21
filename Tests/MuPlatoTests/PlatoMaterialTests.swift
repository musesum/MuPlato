import XCTest
import MuFlo
@testable import MuPlato

/// plato.material and plato.phase as the menu shows them: opacity 1 is
/// opaque, material w is the shading normal, phase w the convex pull. The
/// two w axes traded places, so a stale archive's value is held to the range
/// the axis it lands on declares
final class PlatoMaterialTests: XCTestCase {

    /// cell.flo.h's own declarations, as the app parses them
    static let script = """
    plato {
        material (xyzw, x 0…1=1 'opacity', y 0…1=1 'mirror', z 0…1=0 'zoom', w 0…1=0.1 'normal')
        phase (xyzw, x 0…10=1 'plato', y 0…6=0 'subdiv', z 0…1=0 'zoom', w 0.9…1.1 : 0.98 'convex')
        ico (tog, x 0…1=0, menu 0)
    }
    """
    func flo(_ script: String = script) throws -> (Flo, PlatoFlo) {
        let root = Flo("√")
        XCTAssertTrue(FloParse().parseRoot(root, script))
        return (root, PlatoFlo(root))
    }

    /// the script's defaults reach the shading: opaque, mirrored, unzoomed,
    /// a touch of vertex normal, the solids' own convex, and no spring
    func testDefaults() throws {
        let (_, plato) = try flo()
        XCTAssertEqual(plato.material.x, 1, "opacity")
        XCTAssertEqual(plato.material.y, 1, "mirror")
        XCTAssertEqual(plato.material.z, 0, "zoom")
        XCTAssertEqual(plato.normal, 0.1, accuracy: 1e-6, "material w")
        XCTAssertEqual(plato.convex, 0.98, accuracy: 1e-6, "phase w")
        XCTAssertFalse(plato.ico, "spring off")
        XCTAssertEqual(plato.spring, 0)
    }

    /// each w writes its own var, not the other's
    func testEachWWritesItsOwn() throws {
        let (root, plato) = try flo()
        root.findPath("plato.material")?.setNameNums([("w", 0.75)], .fire, Visitor(0, .user))
        XCTAssertEqual(plato.normal, 0.75, accuracy: 1e-6)
        XCTAssertEqual(plato.convex, 0.98, accuracy: 1e-6, "phase's w stays")
        root.findPath("plato.phase")?.setNameNums([("w", 1.05)], .fire, Visitor(0, .user))
        XCTAssertEqual(plato.convex, 1.05, accuracy: 1e-6)
        XCTAssertEqual(plato.normal, 0.75, accuracy: 1e-6, "material's w stays")
    }

    /// an archive from before the swap merges by axis letter: the old
    /// phase w (a normal, 0…1) would land a 0 in convex, and pow(0, harmonic)
    /// folds every subdivided vertex into the centre
    func testStaleArchiveValuesStayInRange() throws {
        let (root, plato) = try flo()
        root.findPath("plato.phase")?.setNameNums([("w", 0)], .fire, Visitor(0, .user))
        XCTAssertEqual(plato.convex, 0.9, accuracy: 1e-6, "held to the convex range")
        root.findPath("plato.material")?.setNameNums([("w", 0.98)], .fire, Visitor(0, .user))
        XCTAssertEqual(plato.normal, 0.98, accuracy: 1e-6, "a stale convex is a legal normal")
    }
}
