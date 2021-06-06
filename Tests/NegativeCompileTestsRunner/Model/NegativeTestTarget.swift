//
// Created by Andreas Bauer on 02.06.21.
//

import Foundation

struct NegativeTestTarget {
    /// The URL to the directory to the test target.
    let directory: URL
    /// The URL to the `Cases` directory. Located under `${self.directory}/Cases`.
    let casesDirectory: URL

    /// The parsed `NegativeTestCase`s located inside the `Cases` directory
    let cases: [NegativeTestCase]

    let runTestCasesIsolated: Bool

    /// The name of the negative test target
    var name: String {
        directory.lastPathComponent
    }
}
