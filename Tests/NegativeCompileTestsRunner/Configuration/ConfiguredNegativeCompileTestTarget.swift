//
// Created by Andreas Bauer on 06.06.21.
//

import Foundation

// swiftlint:disable discouraged_optional_collection

struct ConfiguredNegativeCompileTestTarget {
    /// The name of the test target (the name of the folder in the `Tests` folder)
    let name: String
    let cases: [ConfiguredTestCase]
    let restrictedTestCases: [String]?

    static func target(
        name: String,
        configurations cases: [ConfiguredTestCase] = [],
        executingOnly testCases: [String]? = nil
    ) -> ConfiguredNegativeCompileTestTarget {
        self.init(name: name, cases: cases)
    }

    private init(name: String, cases: [ConfiguredTestCase], restrictedTestCases: [String]?) {
        self.name = name
        self.cases = cases
        self.testCaseWhitelist = restrictedTestCases
    }

    func isExcludedCase(_ name: String) -> Bool {
        guard let cases = self.restrictedTestCases else {
            return false
        }

        return !cases.contains { testCase in
            testCase == name
        }
    }

    func configuration(forTestCase name: String) -> ConfiguredTestCase? {
        cases.first { testCase in
            testCase.name == name
        }
    }
}
