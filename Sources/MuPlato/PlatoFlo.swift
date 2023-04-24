//  Created by warren on 4/18/23.

import AVFoundation
import CoreMedia
import MuTime // NextFrame
import MuFlo

open class PlatoFlo {

    static public let shared = PlatoFlo()

    public let root = Flo("√")

    public var platoOps = PlatoOps([
        .showCube,
        .showPlato,
        .reflectCube,
        //.cameraBack,
        //.cameraFront,
        //.faceMask,
        .trackMotion,
        //.colorizeTri,
        .colorShade,
        .invertShade,
        .drawFill,
    ])

    var cube˚     : Flo?
    var reflect˚  : Flo?
    var colorize˚ : Flo?
    var wire˚     : Flo?
    var morphing˚ : Flo?
    var morphdex˚ : Flo?

    var cube      = false
    var reflect   = false
    var colorize  = false
    var wire      = false
    var morphing  = false
    var morphdex  = 0

    init() {

        let plato = root.findPath("model.canvas.plato")
        cube˚     = plato?.findPath("cube")
        reflect˚  = cube˚?.findPath("reflect")
        wire˚     = cube˚?.findPath("wire")
        colorize˚ = plato?.findPath("colorize")
        morphing˚ = colorize˚?.findPath("morphing")
        morphdex˚ = colorize˚?.findPath("morphdex")

        cube˚?    .addClosure { t,_ in self.cube     =  t.bool }
        reflect˚? .addClosure { t,_ in self.reflect  =  t.bool }
        wire˚?    .addClosure { t,_ in self.wire     =  t.bool }
        colorize˚?.addClosure { t,_ in self.colorize =  t.bool }
        morphing˚?.addClosure { t,_ in self.morphing =  t.bool }
        morphdex˚?.addClosure { t,_ in self.morphdex =  t.int ?? 1 }
    }
}
