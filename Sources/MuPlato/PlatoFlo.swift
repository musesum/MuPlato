//  Created by warren on 4/18/23.

import AVFoundation
import CoreMedia
import MuTime // NextFrame
import MuFlo

open class PlatoFlo {

    static public let shared = PlatoFlo()

    private var _show    : Flo? ; var show     = false
    private var _coloriz : Flo? ; var coloriz  = false
    private var _colors  : Flo? ; var colors   = CGFloat.zero
    private var _stride  : Flo? ; var stride   = CGFloat.zero
    private var _wire    : Flo? ; var wire     = false
    private var _shadow  : Flo? ; var shadow   = false
    private var _invert  : Flo? ; var invert   = true
    private var _morphing: Flo? ; var morphing = false
    private var _counter : Flo? ; var counter  = Int.zero
    private var _rotate  : Flo? ; var rotate   = CGPoint.zero
    private var _zoom    : Flo? ; var zoom     = CGFloat.zero

    init() {

        let plato = Flo.root.bind("model.canvas.cube.plato")
        _show     = plato    .bind(""        ){ f,_ in self.show     = f.bool    }
        _coloriz  = plato    .bind("coloriz" ){ f,_ in self.coloriz  = f.bool    }
        _colors   = _coloriz?.bind("colors"  ){ f,_ in self.colors   = f.cgFloat }
        _stride   = _coloriz?.bind("stride"  ){ f,_ in self.stride   = f.cgFloat }
        _wire     = _coloriz?.bind("wire"    ){ f,_ in self.wire     = f.bool    }
        _shadow   = _coloriz?.bind("shadow"  ){ f,_ in self.shadow   = f.bool    }
        _invert   = plato    .bind("invert"  ){ f,_ in self.invert   = f.bool    }
        _morphing = plato    .bind("morphing"){ f,_ in self.morphing = f.bool    }
        _counter  = plato    .bind("counter" ){ f,_ in self.counter  = f.int     }
        _rotate   = plato    .bind("rotate"  ){ f,_ in self.rotate   = f.cgPoint }
        _zoom     = plato    .bind("zoom"    ){ f,_ in self.zoom     = f.cgFloat }

    }
}
