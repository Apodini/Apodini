import XCTest
@testable import ApodiniDeploy

final class ApodiniDeployTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(ApodiniDeploy().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
