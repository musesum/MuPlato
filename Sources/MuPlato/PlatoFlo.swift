//  created by musesum on 4/18/23.

import AVFoundation
import CoreMedia
import MuFlo

open class PlatoFlo {

    private var counter˚  : Flo? ; var counter  = Int(0)
    private var material˚ : Flo? ; var material = SIMD3<Float>(x: 1.0, y: 1.0, z: 0.0)
    /**/                           var convex   = Float(0.98) // phase w
    private var run˚      : Flo? ; var run      = true
    private var wire˚     : Flo? ; var wire     = false
    private var alpha˚    : Flo? ; var alpha    = Float(1)
    private var frustum˚  : Flo? ; var frustum  = Float(0) // fov widen: 0 neutral, 1 the radial spokes
    private var ico˚      : Flo? ; var ico      = false        // geodesic ball on springs (WinSky) instead of the centroid-trisected solids
    private var press˚    : Flo? ; var press    = Float(0.5)   // held-press depth at full pressure, ball radii; 0 only the tap ring

    /// balloon pressure: the ico ball is the WinSky spring shape at its
    /// classic pressure; the rigid solids never spring
    var spring: Float { ico ? 0.67 : 0 }

    /// convex and normal traded places on material and phase w, and an
    /// archive saved before that merges its values by axis letter: a stale
    /// w would land a 0 in convex, where pow(0, harmonic) folds the mesh
    /// into its own centre. Each keeps to its own declared range
    static func clamp(_ v: Float, _ lo: Float, _ hi: Float) -> Float { min(max(v, lo), hi) }

    /// one xyzw node carries all four; `.float`/`.int` read only the first
    /// declared scalar, so read the components by name. x and y are declared
    /// `0…10` / `0…6` rather than `0_10` / `0_6` — an integer range on an edge
    /// target decays by span/count on every activation — so round them here
    private var phase˚    : Flo? ; var phase    = Int(1)
    /**/                           var harmonic = Int(0)
    /**/                           var zoom     = Float(0)
    /**/                           var normal   = Float(0.1)  // material w: shading per face (0) … per vertex (1)

    init(_ root˚: Flo) {
        let plato = root˚.bind("plato")
        phase˚    = plato.bind("phase"   ) { f,_ in
            let xyz = f.xyz
            self.phase    = Int(xyz.x.rounded())
            self.harmonic = Int(xyz.y.rounded())
            self.zoom     = xyz.z
            if let w = f.val("w") { self.convex = Self.clamp(Float(w), 0.9, 1.1) }
        }
        material˚ = plato.bind("material") { f,_ in
            self.material = f.xyz
            if let w = f.val("w") { self.normal = Self.clamp(Float(w), 0, 1) }
        }
        // start from the script's w, as the menu shows it: the closures
        // above fire on any of the four, so an x y z edit would otherwise
        // jump convex off its default the first time
        if let w = material˚?.val("w") { normal = Self.clamp(Float(w), 0, 1) }
        if let w = phase˚?.val("w") { convex = Self.clamp(Float(w), 0.9, 1.1) }
        run˚      = plato.bind("run"     ) { f,_ in self.run      = f.bool  }
        wire˚     = plato.bind("wire"    ) { f,_ in self.wire     = f.bool  }
        alpha˚    = plato.bind("alpha"   ) { f,_ in self.alpha    = f.float }
        counter˚  = plato.bind("_counter") { f,_ in self.counter  = f.int   }
        // plato.cube w drives it now, through pipe.render.frustum
        frustum˚  = root˚.bind("pipe.render.frustum") { f,_ in self.frustum = f.float }
        frustum   = frustum˚?.float ?? 0
        ico˚      = plato.bind("ico"     ) { f,_ in self.ico      = f.bool  }
        // an archive restores ico before this binds; the phase header's
        // toggle shows it, so start from it too
        if let on = ico˚?.val("x") { ico = on > 0 }
        press˚    = plato.bind("press"   ) { f,_ in self.press    = f.float }
        // an archive restores press before this binds, as it does ico
        if let x = press˚?.val("x") { press = Float(x) }
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

