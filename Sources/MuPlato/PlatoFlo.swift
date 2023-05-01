//  Created by warren on 4/18/23.

import AVFoundation
import CoreMedia
import MuTime // NextFrame
import MuFlo

open class PlatoFlo {

    static public let shared = PlatoFlo()

    private var colors˚ : Flo? ; var colors = CGPoint.zero
    private var wire˚   : Flo? ; var wire   = false
    private var shadow˚ : Flo? ; var shadow = false
    private var invert˚ : Flo? ; var invert = true
    private var style˚  : Flo? ; var style  = PlatoStyle.reflect

    private var morph˚  : Flo? ; var morph  = true
    private var phase˚  : Flo? ; var phase  = CGPoint.zero
    private var zoom˚   : Flo? ; var zoom   = CGFloat.zero
    private var show˚   : Flo? ; var show   = true

    init() {

        let plato = Flo.root˚.bind("model.canvas.plato")
        let shade  = plato.bind("shade")

        colors˚ = shade.bind("colors") { f,_ in self.colors = f.cgPoint }
        wire˚   = shade.bind("wire"  ) { f,_ in self.wire   = f.bool    }
        shadow˚ = shade.bind("shadow") { f,_ in self.shadow = f.bool    }
        invert˚ = shade.bind("invert") { f,_ in self.invert = f.bool    }
        style˚  = shade.bind("style" ) { f,_ in self.style  = PlatoStyle(f.int) }

        morph˚  = plato.bind("morph" ) { f,_ in self.morph  = f.bool    }
        phase˚  = plato.bind("phase" ) { f,_ in self.phase  = f.cgPoint }
        zoom˚   = plato.bind("zoom"  ) { f,_ in self.zoom   = f.cgFloat }
        show˚   = plato.bind("show"  ) { f,_ in self.show   = f.bool    }
    }
}
