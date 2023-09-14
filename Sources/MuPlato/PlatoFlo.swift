//  Created by warren on 4/18/23.

import AVFoundation
import CoreMedia
import MuFlo

open class PlatoFlo {

    static public let shared = PlatoFlo()

    private var phase˚  : Flo? ; var phase  = CGPoint(x: 0, y: 1)
    private var convex˚ : Flo? ; var convex = Float(1)
    private var colors˚ : Flo? ; var colors = CGPoint.zero
    private var shadow˚ : Flo? ; var shadow = CGPoint.zero
    private var invert˚ : Flo? ; var invert = Float.zero

    private var zoom˚   : Flo? ; var zoom   = Float.zero
    private var morph˚  : Flo? ; var morph  = true
    private var wire˚   : Flo? ; var wire   = false
    private var show˚   : Flo? ; var show   = true

    var harmonif    : Float { convex }
    var colorCount  : Float { Float(colors.x) }
    var colorMix    : Float { Float(colors.y) }
    var shadowWhite : Float { Float(shadow.x) }
    var shadowDepth : Float { Float(shadow.y) }
    
    init() {
        
        let plato = Flo.root˚.bind("model.canvas.plato")
        let shade  = plato.bind("shade")
        
        phase˚  = shade.bind("phase" ) { f,_ in self.phase  = f.cgPoint }
        convex˚ = shade.bind("convex") { f,_ in self.convex = f.float   }
        colors˚ = shade.bind("colors") { f,_ in self.colors = f.cgPoint }
        shadow˚ = shade.bind("shadow") { f,_ in self.shadow = f.cgPoint }
        invert˚ = shade.bind("invert") { f,_ in self.invert = f.float   }
        
        zoom˚   = plato.bind("zoom"  ) { f,_ in self.zoom   = f.float }
        morph˚  = plato.bind("morph" ) { f,_ in self.morph  = f.bool  }
        wire˚   = plato.bind("wire"  ) { f,_ in self.wire   = f.bool  }
        show˚   = plato.bind("show"  ) { f,_ in self.show   = f.bool  }
    }
}
