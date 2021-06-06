//
// Created by Andreas Bauer on 06.06.21.
//

import Foundation

/// This configuration corresponds to a test cases inside the `Cases` folder
/// which is located inside a test target.
struct ConfiguredTestCase {
    /// The name of the test case. This either the name of a file
    /// or the name of a folder located inside the `Cases` folder.
    let name: String
    let platform: Platform

    static func testCase(_ name: String, runningOn platform: Platform = Platform.currentPlatform()) -> ConfiguredTestCase {
        self.init(name: name)
    }

    private init(name: String, platform: Platform) {
        self.name = name
        self.platform = platform
    }

    func runsOnCurrentPlatform() -> Bool {
        platform.contains(Platform.currentPlatform())
    }
}
