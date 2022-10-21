//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import XCTest
import ApodiniUtils

extension XCTestCase {
    /// Whether the test case is running within Xcode.
    /// This will return false when run via the Terminal, e.g. via `swift test`
    public static var isRunningInXcode: Bool {
        ProcessInfo.processInfo.environment["__CFBundleIdentifier"] == "com.apple.dt.Xcode"
    }
    
    /// Skips the current test if the tests are running in Xcode.
    /// This is useful in some cases, since Xcode can sometimes lead to tests behaving differently
    /// as compared to when they're run via the termial, especially when dealing with child processes.
    public func skipIfRunningInXcode() throws {
        if Self.isRunningInXcode {
            throw XCTSkip("Skipping because the test is running in Xcode")
        }
    }
}


/// Asserts that two collections are equal (i.e. contain the same elements) ignoring the element's order.
public func XCTAssertEqualIgnoringOrder<C0: Collection, C1: Collection>(
    _ lhs: C0, _ rhs: C1, file: StaticString = #filePath, line: UInt = #line
) where C0.Element == C1.Element, C0.Element: Hashable {
    guard !lhs.compareIgnoringOrder(rhs) else {
        return
    }
    
    var msg = "Collections '\(C0.self)' and '\(C1.self)' not equal ignoring order.\n"
    msg += "lhs (#=\(lhs.count)):\n"
    for element in lhs {
        msg += "- \(element)\n"
    }
    msg += "rhs (#=\(rhs.count)):\n"
    for element in rhs {
        msg += "- \(element)\n"
    }
    msg += "\n"
    msg += "Elements only in lhs:\n"
    for element in Set(lhs).subtracting(rhs) {
        msg += "- \(element)\n"
    }
    msg += "Elements only in rhs:\n"
    for element in Set(rhs).subtracting(lhs) {
        msg += "- \(element)\n"
    }
    XCTFail(msg, file: file, line: line)
}


/// Asserts that an implication holds.
public func XCTAssertImplication(
    _ condition: @autoclosure () -> Bool,
    _ implication: @autoclosure () -> Bool,
    _ message: @autoclosure () -> String,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    XCTAssert(!condition() || implication(), message(), file: file, line: line)
}


extension XCTestExpectation {
    /// Creates a new `XCTestExpectation` with a description, an expected fulfillment count (which defaults to 1), and an assert-for-overfulfill flag (which defaults to true)
    public convenience init(_ description: String, expectedFulfillmentCount: Int = 1, assertForOverFulfill: Bool = true) {
        self.init(description: description)
        self.expectedFulfillmentCount = expectedFulfillmentCount
        self.assertForOverFulfill = assertForOverFulfill
    }
}


/// XCTUnwrap but it crashes instead of throwing an exception
public func XCTUnwrapWithFatalError<T>(
    _ expression: @autoclosure () -> T?,
    message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) -> T {
    try! XCTUnwrap(expression(), message(), file: file, line: line) // swiftlint:disable:this force_try
}
