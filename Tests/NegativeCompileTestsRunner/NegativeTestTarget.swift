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

    /// The name of the negative test target
    var name: String {
        directory.lastPathComponent
    }
}

struct NegativeTestCase {
    /// Directory or file inside the "Cases" folder which forms one test case
    let fileUrl: URL
    /// The URL to the location the test case files where copied to.
    let destinationUrl: URL

    /// The parsed compiler error declarations found in the files of the test case.
    let expectedErrors: [ExpectedError]
}
