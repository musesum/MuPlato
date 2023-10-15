//  created by musesum on 2/28/23.

import Foundation

extension String {
    func pad(_ len: Int) -> String {
        return self.padding(toLength: len, withPad: " ", startingAt: 0)
    }
}
