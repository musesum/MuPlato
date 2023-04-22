//  Created by warren on 4/18/23.

import AVFoundation
import CoreMedia
import MuTime // NextFrame
import MuFlo


class PlatoFlo {

    static let shared = PlatoFlo()
    let root = Flo("√")

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

    var cube˚      : Flo?
    var reflect˚   : Flo?
    var colorize˚  : Flo?
    var wire˚      : Flo?
    var morphing˚  : Flo?
    var morphdex˚  : Flo?

    var cube       = false
    var reflect    = false
    var colorize   = false
    var wire       = false
    var morphing   = false
    var morphdex   = 0

    init() {
//        let rootNode = MuFloNode(rootFlo)
//        let leftVm  = MenuSkyVm([.lower, .left],  [(rootNode, .vertical),
//                                                   (rootNode, .horizontal)])
//        
//        let midi = root.bindPath("midi")

        cube˚     = root.findPath("cube")
        reflect˚  = root.findPath("reflect")
        colorize˚ = root.findPath("colorize")
        wire˚     = root.findPath("wire")
        morphing˚ = root.findPath("morphing")
        morphdex˚ = root.findPath("morphdex")

        cube˚?     .addClosure { t,_ in self.cube     =  t.bool }
        reflect˚?  .addClosure { t,_ in self.reflect  =  t.bool }
        colorize˚? .addClosure { t,_ in self.colorize =  t.bool }
        wire˚?     .addClosure { t,_ in self.wire     =  t.bool }
        morphing˚? .addClosure { t,_ in self.morphing =  t.bool }
        morphdex˚? .addClosure { t,_ in self.morphdex =  t.int ?? 1 }
    }
}
