//  Created by warren on 3/9/23.
//  Copyright © 2023 com.deepmuse. All rights reserved.

import Foundation
import AVFoundation

public struct PlatoOps: OptionSet {

    public let rawValue: Int

    static let showPlato   = PlatoOps(rawValue: 1 << 0) // show plato object
    static let showCube    = PlatoOps(rawValue: 1 << 1) // show surrounding cube
    static let reflectCube = PlatoOps(rawValue: 1 << 2) // plato object reflects cube
    static let cameraBack  = PlatoOps(rawValue: 1 << 3) // back camera video to cube
    static let cameraFront = PlatoOps(rawValue: 1 << 4) // front camera video to cube
    static let faceMask    = PlatoOps(rawValue: 1 << 5) // mask out face pose
    static let trackMotion = PlatoOps(rawValue: 1 << 6) // track motion to see around
    static let colorizeTri = PlatoOps(rawValue: 1 << 7) // colorize the to triangles
    static let colorShade  = PlatoOps(rawValue: 1 << 8) //  shade the triangles
    static let invertShade = PlatoOps(rawValue: 1 << 9) //  invert triangle shade
    static let drawFill    = PlatoOps(rawValue: 1 << 10) // show faces or lines

    var hasCamera: Bool { get {
        intersection([.cameraFront,.cameraBack]) != []
    }}
    var hasCube: Bool { get {
        return showCube || reflectCube
    }}
    var cameraPosition: AVCaptureDevice.Position { get {
        cameraBack ? .back :
        cameraFront ? .front : .unspecified
    }}

    public var showPlato   : Bool { get { contains(.showPlato  )}}
    public var showCube    : Bool { get { contains(.showCube   )}}
    public var reflectCube : Bool { get { contains(.reflectCube)}}
    public var cameraBack  : Bool { get { contains(.cameraBack )}}
    public var cameraFront : Bool { get { contains(.cameraFront)}}
    public var faceMask    : Bool { get { contains(.faceMask   )}}
    public var trackMotion : Bool { get { contains(.trackMotion)}}
    public var colorizeTri : Bool { get { contains(.colorizeTri)}}
    public var colorShade  : Bool { get { contains(.colorShade )}}
    public var invertShade : Bool { get { contains(.invertShade)}}
    public var drawFill    : Bool { get { contains(.drawFill   )}}

    public var description: String { get {
        var str = "["
        var del = ""
        if showPlato   { add("showPlato"  ) }
        if showCube    { add("showCube"   ) }
        if reflectCube { add("reflectCube") }
        if cameraBack  { add("cameraBack" ) }
        if cameraFront { add("cameraFront") }
        if faceMask    { add("faceMask"   ) }
        if trackMotion { add("trackMotion") }
        if colorizeTri { add("colorizeTri") }
        if colorShade  { add("colorShade" ) }
        if invertShade { add("invertShade") }
        if drawFill    { add("drawFill"   ) }

        str += "]"
        return str

        func add(_ item: String) {
            str += del + item
            del = ", "
        }

    }}

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

