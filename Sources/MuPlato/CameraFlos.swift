// created by musesum on 4/24/23.

import UIKit
import MuFlo

open class CameraFlos: @unchecked Sendable {

    //static let shared = CameraFlos()

    private var stream˚: Flo?
    private var front˚ : Flo?
    private var mask˚  : Flo?
    public private(set) var stream = false
    public private(set) var front = true
    public private(set) var mask  = false

    init(_ root˚: Flo) {
        let camera = root˚.bind("camera")
        stream˚ = camera.bind("stream") { f,_ in self.stream = f.bool }
        front˚  = camera.bind("front" ) { f,_ in self.front  = f.bool }
        mask˚   = camera.bind("mask"  ) { f,_ in self.mask   = f.bool }
    }
}
