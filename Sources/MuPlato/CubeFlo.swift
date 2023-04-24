//  Created by warren on 4/24/23.

import UIKit
import MuFlo

open class CubeFlo {

    static public let shared = CubeFlo()

    public let root = Flo.root

    var show˚    : Flo?
    var reflect˚ : Flo?
    var motion˚  : Flo?
    var rotate˚  : Flo?
    var zoom˚    : Flo?

    var show    = true //???
    var reflect = true //??? 
    var motion  = false
    var rotate  = CGPoint.zero
    var zoom    = CGFloat.zero

    init() {

        guard let cube = root.findPath("model.canvas.cube") else { return }

        show˚    = cube
        reflect˚ = cube.bindPath("reflect")
        motion˚  = cube.bindPath("motion" )
        rotate˚  = cube.bindPath("rotate" )
        zoom˚    = cube.bindPath("zoom"   )

        show˚?   .addClosure { flo,_ in self.show    = flo.bool }
        reflect˚?.addClosure { flo,_ in self.reflect = flo.bool }
        motion˚? .addClosure { flo,_ in self.motion  = flo.bool }
        rotate˚? .addClosure { flo,_ in self.rotate  = flo.cgPoint ?? .zero }
        zoom˚?   .addClosure { flo,_ in self.zoom    = flo.cgFloat ?? .zero }
    }
}

