//  created by musesum on 3/14/23.

import UIKit
import Metal
import MuMetal
import MuFlo
import MuColor
import simd

open class PlatoPipeline: Pipeline {

    var platoNode: PlatoNode!    
    var cameraNode: MetalNode!

    var motion: Motion?
    #if os(visionOS)
    #else
    var facePose: FacePose!
    #endif
    var displayLink: DisplayLink!

    let cameraFlo = CameraFlo.shared
    let cubeFlo = CubeFlo.shared
    let platoFlo = PlatoFlo.shared
    private var colorFlo = ColorFlo(Flo.root˚)

    public init(_ bounds: CGRect,
                _ metalVD: MTLVertexDescriptor) {
        
        super.init(bounds)
        motion = Motion.shared
        setupPipeline(Flo.root˚)
    }

    public func setupPipeline(_ root˚: Flo) {

        metalLayer.pixelFormat = .bgra8Unorm
        metalLayer.framebufferOnly = true

        if cameraFlo.stream {
            cameraNode = CameraNode(root˚, self, "camera", "compute.camera")
            //?? nodes.append(cameraNode)
        }
        if cubeFlo.back {
            cubemapNode = CubemapNode(self, cameraFlo.stream)
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
            platoNode = PlatoNode(self, colorFlo.getMix)
        }
        #if os(visionOS)
        #else
        cameraNode?.setMetalNodeOn(true) {
            Camera.shared.startCamera()
        }
        #endif
        displayLink = DisplayLink(self, fps: 60)

        settingUp = false
    }

    public func pause() {

        if let counter = platoNode.platoMetal.platoModel.counter {
            counter.paused = !counter.paused
            print(counter.paused ? "paused counter: \(counter.counter)" : "running")
        }
    }
}
#if os(visionOS)
#else
extension PlatoPipeline: MetFacePoseDelegate {

    public func didUpdate(_ ciImage: CIImage) {
        
        cubemapNode?.updateCubemap(ciImage)
        didFire()
    }
}
#endif
extension PlatoPipeline: DisplayLinkFire {

    func didFire() {
        if settingUp { return }
        motion?.updateDeviceOrientation()
        drawNodes()
    }

}
