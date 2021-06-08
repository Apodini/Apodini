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
    let runTestCasesIsolated: Bool

    /// Creates a new Negative Test Target Configuration Entry.
    /// - Parameters:
    ///   - name: The name of the test target. Equals the SPM test target name (=directory name).
    ///   - cases: Optionally a list of configurations for the individual test cases.
    ///   - testCases: Optional, if supplied only those test cases in that list are executed.
    ///   - runTestCasesIsolated: If true all test cases are run in a separate `swift build` command. Default=false.
    /// - Returns: The `ConfiguredNegativeCompileTestTarget`.
    static func target(
        name: String,
        configurations cases: [ConfiguredTestCase] = [],
        executingOnly testCases: [String]? = nil,
        isolatedTestCaseBuild runTestCasesIsolated: Bool = false
    ) -> ConfiguredNegativeCompileTestTarget {
        self.init(name: name, cases: cases, restrictedTestCases: testCases, runTestCasesIsolated: runTestCasesIsolated)
    }

    private init(name: String, cases: [ConfiguredTestCase], restrictedTestCases: [String]?, runTestCasesIsolated: Bool) {
        self.name = name
        self.cases = cases
        self.restrictedTestCases = restrictedTestCases
        self.runTestCasesIsolated = runTestCasesIsolated
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
