//  Created by warren on 3/14/23.
//  Copyright © 2023 com.deepmuse. All rights reserved.

import UIKit
import Metal
import MuMetal
import simd

class PlatoPipeline: MetPipeline {

    static var shared = PlatoPipeline()
    
    var platoNode: MetNode!    
    var cameraNode: MetNode!
    var renderNode: MetNode!
    var cubemapNode: MetNodeCubemap!

    var platonic: Platonic!

    var motion: Motion?
    var facePose: MetFacePose!
    var displayLink: MetDisplayLink!

    override init() {
        super.init()
        motion = Motion.shared
        platonic = Platonic(device)
        setupPipeline()
    }

    public override func setupPipeline() {

        metalLayer.pixelFormat = .bgra8Unorm // was bgr10_xr
        metalLayer.framebufferOnly = true

        let platoOps = platonic.platoOps
        if platoOps.hasCamera {
            cameraNode = MetNodeCamera(self, "camera", "pipe.camera")
            nodes.append(cameraNode)
        }
        if platoOps.hasCube {
            cubemapNode = MetNodeCubemap(self, platonic.platoOps.hasCamera)
            let zero = Float.zero
            let f = Float(0.75)
            cubemapNode.addBuffer("frame",  zero)
            cubemapNode.addBuffer("mirror", [zero,zero])
            cubemapNode.addBuffer("repeat", [f,f])
            cubemapNode.isOn = platoOps.showCube

            nodes.append(cubemapNode)
        }
        if platoOps.showPlato {
            platoNode = MetNodePlato(self)
            nodes.append(platoNode)
        }
        assemblePipeline()

        cameraNode?.setMetalNodeOn(true) {
            MetCamera.shared.startCamera()
        }

        displayLink = MetDisplayLink(self, fps: 60)

        settingUp = false
    }

    public func pause() {

        if let counter = platonic?.counter {
            counter.paused.toggle()
            print(counter.paused ? "paused counter: \(counter.counter)" : "running")
        }
    }
}

extension PlatoPipeline: MetFacePoseDelegate {

    func didUpdate(_ ciImage: CIImage) {
        
        cubemapNode?.updateCubemap(ciImage)
        didFire()
    }
}

extension PlatoPipeline: MetDisplayLinkFire {

    func didFire() {
        if settingUp { return }
        motion?.updateDeviceOrientation()
        mtkView.draw()
    }

}
