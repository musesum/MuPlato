import XCTest
import MuFlo
@testable import MuPlato

/// plato.material and plato.phase as the menu shows them: opacity 1 is
/// opaque, material normal is the shading normal, phase convex the convex pull. The
/// two w axes traded places, so a stale archive's value is held to the range
/// the axis it lands on declares
final class PlatoMaterialTests: XCTestCase {

    /// cell.flo.h's own declarations, as the app parses them
    static let script = """
    plato {
        material (xyzw, opacity 0…1=1, mirror 0…1=1, zoom 0…1=0, normal 0…1=0.1)
        phase (xyzw, plato 0…10=1, subdiv 0…6=0, zoom 0…1=0, convex 0.9…1.1 : 0.98)
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
        XCTAssertEqual(plato.normal, 0.1, accuracy: 1e-6, "material normal")
        XCTAssertEqual(plato.convex, 0.98, accuracy: 1e-6, "phase convex")
        XCTAssertFalse(plato.ico, "spring off")
        XCTAssertEqual(plato.spring, 0)
    }

    /// each w writes its own var, not the other's
    func testEachWWritesItsOwn() throws {
        let (root, plato) = try flo()
        root.findPath("plato.material")?.setNameNums([("normal", 0.75)], .fire, Visitor(0, .user))
        XCTAssertEqual(plato.normal, 0.75, accuracy: 1e-6)
        XCTAssertEqual(plato.convex, 0.98, accuracy: 1e-6, "phase's convex stays")
        root.findPath("plato.phase")?.setNameNums([("convex", 1.05)], .fire, Visitor(0, .user))
        XCTAssertEqual(plato.convex, 1.05, accuracy: 1e-6)
        XCTAssertEqual(plato.normal, 0.75, accuracy: 1e-6, "material's normal stays")
    }

    /// an archive from before the swap merges by axis letter: the old
    /// phase w (a normal, 0…1) would land a 0 in convex, and pow(0, harmonic)
    /// folds every subdivided vertex into the centre
    func testStaleArchiveValuesStayInRange() throws {
        let (root, plato) = try flo()
        root.findPath("plato.phase")?.setNameNums([("convex", 0)], .fire, Visitor(0, .user))
        XCTAssertEqual(plato.convex, 0.9, accuracy: 1e-6, "held to the convex range")
        root.findPath("plato.material")?.setNameNums([("normal", 0.98)], .fire, Visitor(0, .user))
        XCTAssertEqual(plato.normal, 0.98, accuracy: 1e-6, "a stale convex is a legal normal")
    }
}

/// plato.spring as the spring leaf writes it: press the left arc's press
/// depth, cover the disk's cover, and the pressure button its child; its right
/// arc writes material's normal, the normal. A touch deforms the ico ball, or a
/// platonic solid while the clock is off
final class PlatoSpringFloTests: XCTestCase {

    static let script = """
    plato {
        material (xyzw, opacity 0…1=1, mirror 0…1=1, zoom 0…1=0, normal 0…1=0.1)
        phase (xyzw, plato 0…10=1, subdiv 0…6=0, zoom 0…1=0, convex 0.9…1.1 : 0.98)
        ico (tog, x 0…1=0, menu 0)
        spring ('the spring ball', spring, press 0…0.8=0.5, cover 0…1=0.4) {
            pressure ('held press', tog, x 0…1=1, menu 0)
        }
        _run ('the clock', tog, x 0_1 : 1)
    }
    """
    func flo() throws -> (Flo, PlatoFlo) {
        let root = Flo("√")
        XCTAssertTrue(FloParse().parseRoot(root, Self.script))
        return (root, PlatoFlo(root))
    }

    func testDefaults() throws {
        let (_, plato) = try flo()
        XCTAssertEqual(plato.press, 0.5, accuracy: 1e-6)
        XCTAssertEqual(plato.cover, 0.4, accuracy: 1e-6)
        XCTAssertEqual(plato.normal, 0.1, accuracy: 1e-6)
        XCTAssertTrue(plato.pressure)
        XCTAssertEqual(plato.material, SIMD3<Float>(1, 1, 0), "material keeps opacity, mirror and zoom")
        XCTAssertTrue(plato.run)
        XCTAssertFalse(plato.deforms, "the platonic morph runs: a touch leaves it be")
    }

    /// each control writes its own var; the normal is material's normal alone,
    /// which the material panel's normal and the spring panel's right arc both set
    func testTheLeafWritesThrough() throws {
        let (root, plato) = try flo()
        let spring = try XCTUnwrap(root.findPath("plato.spring"))
        let material = try XCTUnwrap(root.findPath("plato.material"))
        XCTAssertNil(spring.val("normal"), "one normal: the spring carries none")
        material.setNameNums([("normal", 0.75)], .fire, Visitor(0, .user))
        XCTAssertEqual(plato.normal, 0.75, accuracy: 1e-6)
        XCTAssertEqual(plato.press, 0.5, accuracy: 1e-6, "press stays")
        spring.setNameNums([("press", 0.2), ("cover", 0.9)], .fire, Visitor(0, .user))
        XCTAssertEqual(plato.press, 0.2, accuracy: 1e-6)
        XCTAssertEqual(plato.cover, 0.9, accuracy: 1e-6)
        XCTAssertEqual(plato.normal, 0.75, accuracy: 1e-6, "normal stays")
        root.findPath("plato.spring.pressure")?.setNameNums([("x", 0)], .fire, Visitor(0, .user))
        XCTAssertFalse(plato.pressure)
    }

    /// the ico ball always deforms; a platonic solid while the clock is off
    func testDeforms() throws {
        let (root, plato) = try flo()
        root.findPath("plato._run")?.setNameNums([("x", 0)], .fire, Visitor(0, .user))
        XCTAssertTrue(plato.deforms, "the clock is off")
        root.findPath("plato._run")?.setNameNums([("x", 1)], .fire, Visitor(0, .user))
        XCTAssertFalse(plato.deforms)
        root.findPath("plato.ico")?.setNameNums([("x", 1)], .fire, Visitor(0, .user))
        XCTAssertTrue(plato.deforms, "the ico ball, whatever the clock")
    }

    /// material's opacity, mirror and zoom are read at launch, not first on its first fire:
    /// the script's mirror 0, not the Swift default's 1 (a black mirror)
    func testStartsFromMaterial() throws {
        let (root, plato) = try flo()
        XCTAssertEqual(plato.material, SIMD3<Float>(1, 1, 0), "this script's mirror is 1")
        let root2 = Flo("√")
        XCTAssertTrue(FloParse().parseRoot(root2, Self.script.replacingOccurrences(of: "mirror 0…1=1", with: "mirror 0…1=0")))
        XCTAssertEqual(PlatoFlo(root2).material, SIMD3<Float>(1, 0, 0), "mirror 0 from the start")
        root.findPath("plato.material")?.setNameNums([("opacity", 0.4), ("mirror", 0.3), ("zoom", 0.2)], .fire, Visitor(0, .user))
        XCTAssertEqual(PlatoFlo(root).material, SIMD3<Float>(0.4, 0.3, 0.2), "as restored")
        XCTAssertEqual(PlatoFlo(Flo("√")).material, SIMD3<Float>(1, 1, 0), "no material: the default, not opacity 0")
    }

    /// an archive restores the leaf before PlatoFlo binds: start from it
    func testStartsFromRestoredValues() throws {
        let root = Flo("√")
        XCTAssertTrue(FloParse().parseRoot(root, Self.script))
        root.findPath("plato.spring")?.setNameNums([("press", 0.3), ("cover", 0.7)], .fire, Visitor(0, .user))
        root.findPath("plato.material")?.setNameNums([("normal", 0.6)], .fire, Visitor(0, .user))
        root.findPath("plato.spring.pressure")?.setNameNums([("x", 0)], .fire, Visitor(0, .user))
        root.findPath("plato._run")?.setNameNums([("x", 0)], .fire, Visitor(0, .user))
        let plato = PlatoFlo(root)
        XCTAssertEqual(plato.press, 0.3, accuracy: 1e-6)
        XCTAssertEqual(plato.cover, 0.7, accuracy: 1e-6)
        XCTAssertEqual(plato.normal, 0.6, accuracy: 1e-6)
        XCTAssertFalse(plato.pressure)
        XCTAssertFalse(plato.run, "the clock as restored")
        XCTAssertTrue(plato.deforms)
    }
}
