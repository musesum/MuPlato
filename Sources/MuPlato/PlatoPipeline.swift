//  Created by warren on 3/14/23.
//  Copyright © 2023 com.deepmuse. All rights reserved.

import UIKit
import Metal
import MuMetal
import MuFlo
import MuColor
import simd

open class PlatoPipeline: MetPipeline {

    public static var shared = PlatoPipeline()
    
    var platoNode: MetNode!    
    var cameraNode: MetNode!
    var platonic: Platonic!

    var motion: Motion?
    #if os(xrOS)
    #else
    var facePose: MetFacePose!
    #endif
    var displayLink: MetDisplayLink!

    let cameraFlo = CameraFlo.shared
    let cubeFlo = CubeFlo.shared
    let platoFlo = PlatoFlo.shared
    private var colorFlo = ColorFlo(Flo.root˚)

    override public init() {
        super.init()
        motion = Motion.shared
        platonic = Platonic(device)
        setupPipeline()
    }

    public override func setupPipeline() {

        metalLayer.pixelFormat = .bgra8Unorm // was bgr10_xr
        metalLayer.framebufferOnly = true

        if cameraFlo.stream {
            cameraNode = MetNodeCamera(self, "camera", "compute.camera")
            //?? nodes.append(cameraNode)
        }
        if cubeFlo.back {
            cubemapNode = MetNodeCubemap(self, cameraFlo.stream)
            if let cubemapNode {
                let zero = Float.zero
                let f = Float(0.75)
                cubemapNode.addBuffer("frame",  zero)
                cubemapNode.addBuffer("mirror", [zero,zero])
                cubemapNode.addBuffer("repeat", [f,f])
                cubemapNode.isOn = cubeFlo.show
            }
        }
        if platoFlo.show {
            platoNode = MetNodePlato(self, colorFlo.getMix)
        }
        #if os(xrOS)
        #else
        cameraNode?.setMetalNodeOn(true) {
            MetCamera.shared.startCamera()
        }
        #endif
        displayLink = MetDisplayLink(self, fps: 60)

        settingUp = false
    }

    public func pause() {

        if let counter = platonic?.counter {
            counter.paused = !counter.paused
            print(counter.paused ? "paused counter: \(counter.counter)" : "running")
        }
    }
}
#if os(xrOS)
#else
extension PlatoPipeline: MetFacePoseDelegate {

    public func didUpdate(_ ciImage: CIImage) {
        
        cubemapNode?.updateCubemap(ciImage)
        didFire()
    }
}
#endif
extension PlatoPipeline: MetDisplayLinkFire {

    func didFire() {
        if settingUp { return }
        motion?.updateDeviceOrientation()
        draw()
    }

}
