//  created by musesum on 4/18/23.

import AVFoundation
import CoreMedia
import MuFlo

open class PlatoFlo {

    static public let shared = PlatoFlo()
    private var phase˚    : Flo? ; var phase    = Int(0)
    private var harmonic˚ : Flo? ; var harmonic = Int(1)
    private var convex˚   : Flo? ; var convex   = Float(0.95)
    private var reflect˚  : Flo? ; var reflect  = Float(0.9)
    private var shadow˚   : Flo? ; var shadow   = CGPoint.zero
    private var invert˚   : Flo? ; var invert   = Float.zero
    private var zoom˚     : Flo? ; var zoom     = Float(0.75)
    private var run˚      : Flo? ; var run      = true
    private var wire˚     : Flo? ; var wire     = false
    private var show˚     : Flo? ; var show     = true

    var alpha : Float { Float(shadow.x) }
    var depth : Float { Float(shadow.y) }
    
    init() {
        
        let plato = Flo.root˚.bind("model.plato")
        let more  = plato.bind("more")
        let show = Flo.root˚.bind("model.more.show")

        reflect˚  = plato.bind("reflect" ) { f,_ in self.reflect  = f.float }
        invert˚   = plato.bind("invert"  ) { f,_ in self.invert   = f.float }
        shadow˚   = plato.bind("shadow"  ) { f,_ in self.shadow   = f.cgPoint }
        zoom˚     = plato.bind("zoom"    ) { f,_ in self.zoom     = f.float }
        convex˚   = plato.bind("convex"  ) { f,_ in self.convex   = f.float }

        wire˚     = more.bind("wire"     ) { f,_ in self.wire     = f.bool  }
        phase˚    = more.bind("phase"    ) { f,_ in self.phase    = f.int }
        harmonic˚ = more.bind("harmonic" ) { f,_ in self.harmonic = f.int }
        run˚      = more.bind("run"      ) { f,_ in self.run      = f.bool  }
        show˚     = show.bind("plato"    ) { f,_ in self.show     = f.bool  }
    }
}
