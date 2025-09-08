//  created by musesum on 4/18/23.

import AVFoundation
import CoreMedia
import MuFlo

open class PlatoFlo {

    private var counter˚  : Flo? ; var counter  = Int(0)
    private var phase˚    : Flo? ; var phase    = Int(0)
    private var harmonic˚ : Flo? ; var harmonic = Int(1)
    private var convex˚   : Flo? ; var convex   = Float(0.95)
    private var material˚ : Flo? ; var material = SIMD3<Float>(x: 0.0, y: 0.0, z: 1.0)
    private var zoom˚     : Flo? ; var zoom     = Float(0)
    private var run˚      : Flo? ; var run      = true
    private var wire˚     : Flo? ; var wire     = false
    private var alpha˚    : Flo? ; var alpha    = Float(1)

    init(_ root˚: Flo) {
        let plato = root˚.bind("plato")
        zoom˚     = plato.bind("zoom"    ) { f,_ in self.zoom     = f.float }
        material˚ = plato.bind("material") { f,_ in self.material = f.xyz   }
        harmonic˚ = plato.bind("harmonic") { f,_ in self.harmonic = f.int   }
        phase˚    = plato.bind("phase"   ) { f,_ in self.phase    = f.int   }
        convex˚   = plato.bind("convex"  ) { f,_ in self.convex   = f.float }
        run˚      = plato.bind("run"     ) { f,_ in self.run      = f.bool  }
        wire˚     = plato.bind("wire"    ) { f,_ in self.wire     = f.bool  }
        alpha˚    = plato.bind("alpha"   ) { f,_ in self.alpha    = f.float }
        counter˚  = plato.bind("_counter") { f,_ in self.counter  = f.int   }
    }
}

open class ElipseFlo {


    private var harmonic˚ : Flo? ; var harmonic = Int(1)
    private var convex˚   : Flo? ; var convex   = Float(0.95)
    private var material˚ : Flo? ; var material = SIMD3<Float>(x: 0.0, y: 0.0, z: 1.0)
    private var zoom˚     : Flo? ; var zoom     = Float(0)
    private var wire˚     : Flo? ; var wire     = false
    private var alpha˚    : Flo? ; var alpha    = Float(1)

    init(_ root˚: Flo) {
        let plato = root˚.bind("plato")
        zoom˚     = plato.bind("zoom"    ) { f,_ in self.zoom     = f.float }
        material˚ = plato.bind("material") { f,_ in self.material = f.xyz   }
        harmonic˚ = plato.bind("harmonic") { f,_ in self.harmonic = f.int   }
        wire˚     = plato.bind("wire"    ) { f,_ in self.wire     = f.bool  }
        alpha˚    = plato.bind("alpha"   ) { f,_ in self.alpha    = f.float }
    }
}

