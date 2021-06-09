//
// Created by Andreas Bauer on 06.06.21.
//

import Foundation

struct NegativeTestCase {
    /// Directory or file inside the "Cases" folder which forms one test case
    let fileUrl: URL
    /// The URL to the location the test case files where copied to.
    let destinationUrl: URL

    /// The parsed compiler error declarations found in the files of the test case.
    let expectedErrors: [ExpectedError]
}

extension NegativeTestCase: Equatable {
    public static func == (lhs: NegativeTestCase, rhs: NegativeTestCase) -> Bool {
        lhs.fileUrl == rhs.fileUrl
    }
}
