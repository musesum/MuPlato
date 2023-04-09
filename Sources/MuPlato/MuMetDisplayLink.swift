//  Created by warren on 3/18/23.
//  Copyright © 2023 com.deepmuse. All rights reserved.

import Foundation
import MetalKit

protocol MetDisplayLinkFire {
    func didFire()
}
class MetDisplayLink {

    var link: CADisplayLink?
    var linkFire: MetDisplayLinkFire
    var fps: NSInteger = 60

    init(_ linkFire: MetDisplayLinkFire, fps: Int = 60) {
        self.linkFire = linkFire
        self.fps = fps
        addDisplayLink()
    }

    /// not used, right now
    func addDisplayLink() {
        link = UIScreen.main.displayLink(withTarget: self, selector: #selector(displayLinkDidFire))
        link?.preferredFramesPerSecond = fps
        link?.add(to: RunLoop.current, forMode: .default)
    }

    /// not used, right now
    @objc func displayLinkDidFire() -> Bool {
        linkFire.didFire()
        return true
    }


}
