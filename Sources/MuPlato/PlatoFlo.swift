//  created by musesum on 4/18/23.

import AVFoundation
import CoreMedia
import MuFlo

open class PlatoFlo {

    static public let shared = PlatoFlo()
    private var phase˚    : Flo? ; var phase    = Int(0)
    private var harmonic˚ : Flo? ; var harmonic = Int(1)
    private var convex˚   : Flo? ; var convex   = Float(0.95)

    private var shadow˚   : Flo? ; var shadow   = CGPoint.zero
    private var material˚ : Flo? ; var material = CGPoint(x: 0.0, y: 0.9)
    private var zoom˚     : Flo? ; var zoom     = Float(0.75)
    private var run˚      : Flo? ; var run      = true
    private var wire˚     : Flo? ; var wire     = false
    private var show˚     : Flo? ; var show     = true

    var alpha : Float { Float(shadow.x) }
    var depth : Float { Float(shadow.y) }
    
    init() {
        
        let plato = Flo.root˚.bind("model.plato")
        let more = plato.bind("more")
        let show = Flo.root˚.bind("model.more.show")

        zoom˚     = plato.bind("zoom"     ) { f,_ in self.zoom     = f.float   }
        shadow˚   = plato.bind("shadow"   ) { f,_ in self.shadow   = f.cgPoint }
        material˚ = plato.bind("material" ) { f,_ in self.material = f.cgPoint }
        phase˚    = plato.bind("phase"    ) { f,_ in self.phase    = f.int     }
        harmonic˚ = plato.bind("harmonic" ) { f,_ in self.harmonic = f.int     }

        convex˚   = more.bind("convex"    ) { f,_ in self.convex   = f.float   }
        wire˚     = more.bind("wire"      ) { f,_ in self.wire     = f.bool    }
        run˚      = more.bind("run"       ) { f,_ in self.run      = f.bool    }
        show˚     = show.bind("plato"     ) { f,_ in self.show     = f.bool    }
    }
}

