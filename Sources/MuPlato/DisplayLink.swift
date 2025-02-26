//  created by musesum on 3/18/23.

import Foundation
import MetalKit

protocol DisplayLinkFire {
    func didFire()
}
class DisplayLink {
    
    var link: CADisplayLink?
    var linkFire: DisplayLinkFire
    var fps: NSInteger = 60
    
    init(_ linkFire: DisplayLinkFire, fps: Int = 60) {
        self.linkFire = linkFire
        self.fps = fps
        link = CADisplayLink(target: self, selector: #selector(displayLinkDidFire))
        link?.preferredFramesPerSecond = fps
        link?.add(to: RunLoop.current, forMode: .common)
    }
    
    /// not used, right now
    @objc func displayLinkDidFire() -> Bool {
        linkFire.didFire()
        return true
    }
    
    
}
