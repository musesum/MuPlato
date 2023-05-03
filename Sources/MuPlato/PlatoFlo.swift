//  Created by warren on 4/18/23.

import AVFoundation
import CoreMedia
import MuTime // NextFrame
import MuFlo

open class PlatoFlo {

    static public let shared = PlatoFlo()

    private var phase˚  : Flo? ; var phase  = CGPoint.zero
    private var colors˚ : Flo? ; var colors = CGPoint.zero
    private var shadow˚ : Flo? ; var shadow = CGPoint.zero
    private var invert˚ : Flo? ; var invert = CGFloat.zero

    private var zoom˚   : Flo? ; var zoom   = CGFloat.zero
    private var morph˚  : Flo? ; var morph  = true
    private var wire˚   : Flo? ; var wire   = false
    private var show˚   : Flo? ; var show   = true

    init() {

        let plato = Flo.root˚.bind("model.canvas.plato")
        let shade  = plato.bind("shade")

        phase˚  = shade.bind("phase" ) { f,_ in self.phase  = f.cgPoint }
        colors˚ = shade.bind("colors") { f,_ in self.colors = f.cgPoint }
        shadow˚ = shade.bind("shadow") { f,_ in self.shadow = f.cgPoint }
        invert˚ = shade.bind("invert") { f,_ in self.invert = f.cgFloat }

        zoom˚   = plato.bind("zoom"  ) { f,_ in self.zoom   = f.cgFloat }
        morph˚  = plato.bind("morph" ) { f,_ in self.morph  = f.bool    }
        wire˚   = plato.bind("wire"  ) { f,_ in self.wire   = f.bool    }
        show˚   = plato.bind("show"  ) { f,_ in self.show   = f.bool    }
    }
}
