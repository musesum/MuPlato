//  Created by warren on 2/28/23.
//  Copyright © 2023 com.deepmuse. All rights reserved

import Foundation

extension String {
    func pad(_ len: Int) -> String {
        return self.padding(toLength: len, withPad: " ", startingAt: 0)
    }
}
