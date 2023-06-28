// Created by warren on 4/24/23.

import UIKit
import MuFlo

open class CameraFlo {

    static public let shared = CameraFlo()

    private var stream˚: Flo? ; var stream = false
    private var front˚ : Flo? ; var front  = false
    private var mask˚  : Flo? ; var mask   = false

    init() {

        let camera = Flo.root˚.bind("model.camera")
        stream˚ = camera.bind("stream") { f,_ in self.stream = f.bool }
        front˚  = camera.bind("front" ) { f,_ in self.front  = f.bool }
        mask˚   = camera.bind("mask"  ) { f,_ in self.mask   = f.bool }
    }
}
