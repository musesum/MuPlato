//  Created by warren on 4/18/23.

import AVFoundation
import CoreMedia
import MuTime // NextFrame
import MuFlo

open class PlatoFlo {

    static public let shared = PlatoFlo()

    public let root = Flo.root

    var show˚    : Flo?
    var wire˚    : Flo?
    var morping˚ : Flo?

    var coloriz˚ : Flo?
    var colors˚  : Flo?
    var stride˚  : Flo?
    var shadow˚  : Flo?
    var invert˚  : Flo?

    var counter˚ : Flo?
    var rotate˚  : Flo?

    var show     = false
    var wire     = false
    var morping  = false

    var coloriz  = false
    var colors   = CGFloat.zero
    var stride   = CGFloat.zero
    var shadow   = false
    var invert   = false

    var counter = Int.zero
    var rotate  = CGPoint.zero

    init() {

        guard let plato = root.findPath("model.canvas.plato") else { return }

        show˚    = plato
        wire˚    = plato.bindPath("plato.wire"   )
        morping˚ = plato.bindPath("plato.morping")
        counter˚ = plato.bindPath("plato.counter")

        coloriz˚ = plato.bindPath("plato.coloriz")
        colors˚  = plato.bindPath("plato.coloriz.colors")
        stride˚  = plato.bindPath("plato.coloriz.stride")
        shadow˚  = plato.bindPath("plato.coloriz.shadow")
        invert˚  = plato.bindPath("plato.coloriz.invert")

        rotate˚  = plato.bindPath("plato.rotate")

        show˚?    .addClosure { flo,_ in self.show    = flo.bool }
        wire˚?    .addClosure { flo,_ in self.wire    = flo.bool }
        morping˚? .addClosure { flo,_ in self.morping = flo.bool }

        coloriz˚? .addClosure { flo,_ in self.coloriz = flo.bool }
        colors˚?  .addClosure { flo,_ in self.colors  = flo.cgFloat ?? .zero }
        stride˚?  .addClosure { flo,_ in self.stride  = flo.cgFloat ?? .zero }
        shadow˚?  .addClosure { flo,_ in self.shadow  = flo.bool }
        invert˚?  .addClosure { flo,_ in self.invert  = flo.bool }

        counter˚? .addClosure { flo,_ in self.counter = flo.int ?? 0 }
        rotate˚?  .addClosure { flo,_ in self.rotate  = flo.cgPoint ?? .zero }
    }
}

