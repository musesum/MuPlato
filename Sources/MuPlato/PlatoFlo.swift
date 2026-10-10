//  created by musesum on 4/18/23.

import AVFoundation
import CoreMedia
import MuFlo

open class PlatoFlo {

    private var counter˚  : Flo? ; var counter  = Int(0)
    private var material˚ : Flo? ; var material = SIMD3<Float>(x: 1.0, y: 1.0, z: 0.0)
    /**/                           var convex   = Float(0.98) // phase convex
    private var run˚      : Flo? ; var run      = true
    private var wire˚     : Flo? ; var wire     = false
    private var alpha˚    : Flo? ; var alpha    = Float(1)
    private var frustum˚  : Flo? ; var frustum  = Float(0) // fov widen: 0 neutral, 1 the radial spokes
    private var ico˚      : Flo? ; var ico      = false        // geodesic ball on springs (WinSky) instead of the centroid-trisected solids

    /// plato.spring, the spring ball's own leaf: press its left arc, cover its disk,
    /// and its pressure button; its right arc is material's normal, the normal below
    private var springs˚  : Flo? ; var press    = Float(0.5)   // press: held-press depth at full pressure, ball radii
    /**/                           var cover    = Float(0.4)   // cover: how much of the ball a touch covers, 0.4 the width the mesh allows it
    private var pressure˚ : Flo? ; var pressure = true         // off: a touch leaves the ball be

    /// balloon pressure: the ico ball is the WinSky spring shape at its
    /// classic pressure; the platonic solids have none
    var spring: Float { ico ? 0.67 : 0 }
    /// a touch moves the vertices: the ico ball's always, a platonic
    /// solid's while the clock is off and it holds still
    var deforms: Bool { ico || !run }

    /// convex and normal traded places on material's normal and phase's convex, and an
    /// archive saved before that merges its values by axis letter: a stale
    /// normal would land a 0 in convex, where pow(0, harmonic) folds the mesh
    /// into its own centre. Each keeps to its own declared range
    static func clamp(_ v: Float, _ lo: Float, _ hi: Float) -> Float { min(max(v, lo), hi) }
    /// the tweens of three named components, .zero when one is missing, as Flo.xyz reads x y z
    static func tweens(_ f: Flo, _ x: String, _ y: String, _ z: String) -> SIMD3<Float> {
        if let exprs = f.exprs,
           let tx = (exprs.nameAny[x] as? Scalar)?.tween,
           let ty = (exprs.nameAny[y] as? Scalar)?.tween,
           let tz = (exprs.nameAny[z] as? Scalar)?.tween {
            return SIMD3<Float>(Float(tx), Float(ty), Float(tz))
        }
        return .zero
    }

    /// one xyzw node carries all four; `.float`/`.int` read only the first
    /// declared scalar, so read the components by name. plato and subdiv are declared
    /// `0…10` / `0…6` rather than `0_10` / `0_6` — an integer range on an edge
    /// target decays by span/count on every activation — so round them here
    private var phase˚    : Flo? ; var phase    = Int(1)
    /**/                           var harmonic = Int(0)
    /**/                           var zoom     = Float(0)
    /**/                           var normal   = Float(0.1)  // material normal, the spring leaf's right arc too: shading per face (0) … per vertex (1)

    init(_ root˚: Flo) {
        let plato = root˚.bind("plato")
        phase˚    = plato.bind("phase"   ) { f,_ in
            let xyz = Self.tweens(f, "plato", "subdiv", "zoom")
            self.phase    = Int(xyz.x.rounded())
            self.harmonic = Int(xyz.y.rounded())
            self.zoom     = xyz.z
            if let w = f.val("convex") { self.convex = Self.clamp(Float(w), 0.9, 1.1) }
        }
        material˚ = plato.bind("material") { f,_ in
            self.material = Self.tweens(f, "opacity", "mirror", "zoom")
            if let w = f.val("normal") { self.normal = Self.clamp(Float(w), 0, 1) }
        }
        // start from the script's normal, as the menu shows it: the closures
        // above fire on any of the four, so an opacity, mirror or zoom edit would otherwise
        // jump convex off its default the first time
        if let w = material˚?.val("normal") { normal = Self.clamp(Float(w), 0, 1) }
        // and from its opacity, mirror and zoom: bind adds the closure without running it, so
        // until material first fired the solid drew at the Swift default's
        // mirror 1, a black mirror on a fresh launch. A script without all
        // three keeps the default: tweens reads a missing one as 0, opacity 0
        if let f = material˚, f.val("opacity") != nil, f.val("mirror") != nil, f.val("zoom") != nil {
            material = Self.tweens(f, "opacity", "mirror", "zoom")
        }
        if let w = phase˚?.val("convex") { convex = Self.clamp(Float(w), 0.9, 1.1) }
        run˚      = plato.bind("run"     ) { f,_ in self.run      = f.bool  }
        // an archive restores the clock before this binds, as it does ico
        if let on = run˚?.val("x") { run = on > 0 }
        wire˚     = plato.bind("wire"    ) { f,_ in self.wire     = f.bool  }
        alpha˚    = plato.bind("alpha"   ) { f,_ in self.alpha    = f.float }
        counter˚  = plato.bind("_counter") { f,_ in self.counter  = f.int   }
        // plato.cube frustum drives it now, through pipe.render.frustum
        frustum˚  = root˚.bind("pipe.render.frustum") { f,_ in self.frustum = f.float }
        frustum   = frustum˚?.float ?? 0
        ico˚      = plato.bind("ico"     ) { f,_ in self.ico      = f.bool  }
        // an archive restores ico before this binds; the phase header's
        // toggle shows it, so start from it too
        if let on = ico˚?.val("x") { ico = on > 0 }
        // an archive restores these before they bind, as it does ico:
        // start from them
        springs˚  = plato.bind("spring"  ) { f,_ in self.readSpring(f) }
        if let f = springs˚ { readSpring(f) }
        pressure˚ = plato.bind("spring.pressure") { f,_ in self.pressure = f.bool }
        if let on = pressure˚?.val("x") { pressure = on > 0 }
    }
    private func readSpring(_ f: Flo) {
        if let x = f.val("press") { press  = Float(x) }
        if let y = f.val("cover") { cover  = Self.clamp(Float(y), 0, 1) }
    }
}

open class ElipseFlo {


    private var convex˚   : Flo? ; var convex   = Float(0.95)
    private var material˚ : Flo? ; var material = SIMD3<Float>(x: 0.0, y: 0.0, z: 1.0)
    private var wire˚     : Flo? ; var wire     = false
    private var alpha˚    : Flo? ; var alpha    = Float(1)

    private var phase˚    : Flo? ; var harmonic = Int(0)
    /**/                           var zoom     = Float(0)

    init(_ root˚: Flo) {
        let plato = root˚.bind("plato")
        phase˚    = plato.bind("phase"   ) { f,_ in
            let xyz = f.xyz
            self.harmonic = Int(xyz.y.rounded())
            self.zoom     = xyz.z
        }
        material˚ = plato.bind("material") { f,_ in self.material = f.xyz   }
        wire˚     = plato.bind("wire"    ) { f,_ in self.wire     = f.bool  }
        alpha˚    = plato.bind("alpha"   ) { f,_ in self.alpha    = f.float }
    }
}

