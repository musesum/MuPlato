//  created by musesum on 4/24/23.

import UIKit
import MuFlo

open class CubeFlo {

    static public let shared = CubeFlo()

    private var motion˚ : Flo? ; var motion = false
    private var rotate˚ : Flo? ; var rotate = CGPoint.zero
    private var back˚   : Flo? ; var back   = true
    private var show˚   : Flo? ; var show   = true

    init() {
        let cube = Flo.root˚.bind("model.canvas.cube")
        motion˚ = cube.bind("motion" ) { f,_ in self.motion = f.bool }
        rotate˚ = cube.bind("rotate" ) { f,_ in self.rotate = f.cgPoint }
        back˚   = cube.bind("back"   ) { f,_ in self.back   = f.bool }
        show˚   = cube.bind("show"   ) { f,_ in self.show   = f.bool }
    }
}
