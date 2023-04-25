//  Created by warren on 4/24/23.

import UIKit
import MuFlo

open class CubeFlo {

    static public let shared = CubeFlo()

    private var show˚   : Flo? ; var show    = true
    private var reflect˚: Flo? ; var reflect = true
    private var motion˚ : Flo? ; var motion  = false
    private var rotate˚ : Flo? ; var rotate  = CGPoint.zero
    private var plato˚  : Flo? ; var plato   = true
    private var fill˚   : Flo? ; var fill    = true

    init() {
        let cube = Flo.root.bind("model.canvas.cube")
        show˚    = cube.bind(""       ) { f,_ in self.show    = f.bool }
        reflect˚ = cube.bind("reflect") { f,_ in self.reflect = f.bool }
        motion˚  = cube.bind("motion" ) { f,_ in self.motion  = f.bool }
        rotate˚  = cube.bind("rotate" ) { f,_ in self.rotate  = f.cgPoint }
        plato˚   = cube.bind("plato"  ) { f,_ in self.plato   = f.bool }
        fill˚    = cube.bind("fill"   ) { f,_ in self.fill    = f.bool }
    }
}

