//  created by musesum on 4/24/23.

import UIKit
import MuFlo

open class CubeFlo {

    static public let shared = CubeFlo()

    private var motion˚ : Flo? ; var motion = false
    private var rotate˚ : Flo? ; var rotate = CGPoint.zero
    private var canvas˚ : Flo? ; var canvas = true
    private var show˚   : Flo? ; var show   = true

    init() {
        let more = Flo.root˚.bind("model.more")
        let show = Flo.root˚.bind("model.more.show")
        motion˚ = more.bind("motion" ) { f,_ in self.motion = f.bool }
        rotate˚ = more.bind("rotate" ) { f,_ in self.rotate = f.cgPoint }
        canvas˚ = show.bind("canvas" ) { f,_ in self.canvas = f.bool }
        show˚   = show.bind("cubemap") { f,_ in self.show   = f.bool }
    }
}
