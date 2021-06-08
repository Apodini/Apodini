//
//  ApodiniDeployTestCase.swift
//  
//
//  Created by Lukas Kollmer on 16.02.21.
//

import Foundation
import XCTApodini
@testable import ApodiniDeploy
import ApodiniUtils


/// The base class for all test cases which test deployment providers.
/// This class intentionally does not inherit from `XCTApodiniTest`, the reason being that
/// that class creates an implicit `Apodini.Application`, which we do not need when testing the deployment providers.
class ApodiniDeployTestCase: XCTestCase {
    struct ApodiniDeployTestError: Swift.Error {
        let message: String
    }
    
    /// Name of the test web service target (used by e.g. the web service exporter tests).
    /// Note that this is **not** the web service in the Tests/ApodiniDeploy/Resources folder, but the target in Sources/ApodiniDeployTestWebService
    static let apodiniDeployTestWebServiceTargetName = "ApodiniDeployTestWebService"
    
    /// Url of the test web service's executable, as compiled by SPM or Xcode
    static var apodiniDeployTestWebServiceTargetUrl: URL {
        urlOfBuildProduct(named: apodiniDeployTestWebServiceTargetName)
    }
    
    
    static var productsDirectory: URL {
        let bundle = Bundle(for: Self.self)
        #if os(macOS)
        return bundle.bundleURL.deletingLastPathComponent()
        #else
        return bundle.bundleURL
        #endif
    }
    
    
    static var shouldRunDeploymentProviderTests: Bool {
        ProcessInfo.processInfo.environment["ENABLE_DEPLOYMENT_PROVIDER_TESTS"] != nil
            || ProcessInfo.processInfo.environment["AD_APODINI_SOURCE_ROOT"] != nil
    }
    
    
    static func urlOfBuildProduct(named productName: String) -> URL {
        productsDirectory.appendingPathComponent(productName)
    }
    
    
    private static var cachedTmpDirSrcRoot: URL?
    
    /// Copies the entire Apodini source code into a temporary directory.
    /// This can be used for testing deployment providers, which usually require
    /// Apodini's and the to-be-deployed web service's source code be present.
    static func replicateApodiniSrcRootInTmpDir() throws -> URL {
        if let path = ProcessInfo.processInfo.environment["AD_APODINI_SOURCE_ROOT"] {
            return URL(fileURLWithPath: path)
        }
        if let url = cachedTmpDirSrcRoot {
            return url
        }
        let fileManager = FileManager.default
        let srcRoot = getApodiniRepoSourceRoot()
        let tmpDir = fileManager.temporaryDirectory
            .appendingPathComponent("ADT_\(UUID().uuidString)", isDirectory: true)
        try fileManager.copyItem(at: URL(fileURLWithPath: srcRoot), to: tmpDir)
        try fileManager.removeItem(at: tmpDir.appendingPathComponent(".build", isDirectory: true))
        cachedTmpDirSrcRoot = tmpDir
        return tmpDir
    }
    
    
    static func getApodiniRepoSourceRoot() -> String {
        let components = URL(fileURLWithPath: #filePath).pathComponents
        let expectedTrailingComponents = ["Tests", "ApodiniDeployTests", "ApodiniDeployTestCase.swift"]
        let index = components.count - expectedTrailingComponents.count // index of the 1st expected trailing component
        precondition(expectedTrailingComponents[...] == components[index...])
        return components[..<index].joined(separator: FileManager.pathSeparator)
    }
    
    
    private struct ReadEnvironmentVariableError: Swift.Error, LocalizedError {
        let key: String
        
        var errorDescription: String? {
            "Unable to read environment variable for key '\(key)'"
        }
    }
    
    static func readEnvironmentVariable(_ key: String) throws -> String {
        if let value = ProcessInfo.processInfo.environment[key] {
            return value
        } else {
            throw ReadEnvironmentVariableError(key: key)
        }
    }
    
    
    func makeError(message: String) -> Error {
        ApodiniDeployTestError(message: message)
    }
}


// MARK: XCT Utils

extension XCTestCase {
    static func isRunningOnLinuxDebug() -> Bool {
        #if os(Linux) && (DEBUG || RELEASE_TESTING)
        return true
        #else
        return false
        #endif
    }
}

/// Asserts that two collections are equal (i.e. contain the same elements) ignoring the element's order.
func XCTAssertEqualIgnoringOrder<C0: Collection, C1: Collection>(
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
    XCTFail(msg, file: file, line: line)
}


/// Asserts that an implication holds.
func XCTAssertImplication(
    _ condition: @autoclosure () -> Bool,
    _ implication: @autoclosure () -> Bool,
    _ message: @autoclosure () -> String,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    XCTAssert(!condition() || implication(), message(), file: file, line: line)
}


extension XCTestExpectation {
    convenience init(_ description: String, expectedFulfillmentCount: Int = 1, assertForOverFulfill: Bool = true) {
        self.init(description: description)
        self.expectedFulfillmentCount = expectedFulfillmentCount
        self.assertForOverFulfill = assertForOverFulfill
    }
}


func XCTUnwrapWithFatalError<T>(
    _ expression: @autoclosure () -> T?,
    message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) -> T {
    try! XCTUnwrap(expression(), message(), file: file, line: line) // swiftlint:disable:this force_try
}
