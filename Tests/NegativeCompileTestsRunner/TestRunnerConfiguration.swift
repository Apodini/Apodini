//
// Created by Andreas Bauer on 02.06.21.
//

import Foundation

// swiftlint:disable discouraged_optional_collection

typealias TestRunnerConfiguration = [ConfiguredNegativeCompileTestTarget]

struct ConfiguredNegativeCompileTestTarget {
    /// The name of the test target (the name of the folder in the `Tests` folder)
    let name: String
    let cases: [ConfiguredTestCase]?

    static func target(_ name: String, executingOnly cases: [ConfiguredTestCase]? = nil) -> ConfiguredNegativeCompileTestTarget {
        self.init(name: name, cases: cases)
    }

    private init(name: String, cases: [ConfiguredTestCase]?) {
        self.name = name
        self.cases = cases
    }

    func isExcludedCase(_ name: String) -> Bool {
        guard let cases = self.cases else {
            return false
        }

        return !cases.contains { testCase in
            testCase.name == name
        }
    }
}

/// This configuration corresponds to a test cases inside the `Cases` folder
/// which is located inside a test target.
struct ConfiguredTestCase {
    /// The name of the test case. This either the name of a file
    /// or the name of a folder located inside the `Cases` folder.
    let name: String

    static func testCase(_ name: String) -> ConfiguredTestCase {
        self.init(name: name)
    }

    private init(name: String) {
        self.name = name
    }
}
