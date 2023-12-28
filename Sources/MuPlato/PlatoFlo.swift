//  created by musesum on 4/18/23.

import AVFoundation
import CoreMedia
import MuFlo

open class PlatoFlo {

    static public let shared = PlatoFlo()
    private var phase˚    : Flo? ; var phase    = Int(0)
    private var harmonic˚ : Flo? ; var harmonic = Int(1)
    private var convex˚   : Flo? ; var convex   = Float(0.95)
    private var passthru˚ : Flo? ; var passthru = Float(0.9)
    private var shadow˚   : Flo? ; var shadow   = CGPoint.zero
    private var invert˚   : Flo? ; var invert   = Float.zero
    private var zoom˚     : Flo? ; var zoom     = Float(0.75)
    private var run˚      : Flo? ; var run      = true
    private var wire˚     : Flo? ; var wire     = false
    private var show˚     : Flo? ; var show     = true

    var shadowWhite : Float { Float(shadow.x) }
    var shadowDepth : Float { Float(shadow.y) }
    
    init() {
        
        let plato = Flo.root˚.bind("model.canvas.plato")
        let extra  = plato.bind("extra")

        passthru˚ = plato.bind("passthru") { f,_ in self.passthru = f.float }
        shadow˚   = plato.bind("shadow"  ) { f,_ in self.shadow   = f.cgPoint }
        zoom˚     = plato.bind("zoom"    ) { f,_ in self.zoom     = f.float }
        convex˚   = plato.bind("convex"  ) { f,_ in self.convex   = f.float }
        show˚     = plato.bind("show"    ) { f,_ in self.show     = f.bool  }

        wire˚     = extra.bind("wire"    ) { f,_ in self.wire     = f.bool  }
        phase˚    = extra.bind("phase"   ) { f,_ in self.phase    = f.int }
        harmonic˚ = extra.bind("harmonic") { f,_ in self.harmonic = f.int }
        invert˚   = extra.bind("invert"  ) { f,_ in self.invert   = f.float }
        run˚      = plato.bind("run"     ) { f,_ in self.run      = f.bool  }

    }
}
