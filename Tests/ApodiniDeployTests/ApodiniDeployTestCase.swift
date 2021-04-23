//
//  ApodiniDeployTestCase.swift
//  
//
//  Created by Lukas Kollmer on 16.02.21.
//

import Foundation
import XCTApodini
@testable import ApodiniDeploy


class ApodiniDeployTestCase: XCTApodiniTest {
    static let apodiniDeployTestWebServiceTargetName = "ApodiniDeployTestWebService"
    
    static var apodiniDeployTestWebServiceTargetUrl: URL {
        urlOfBuildProduct(named: apodiniDeployTestWebServiceTargetName)
    }
    
    
    static func isRunningOnLinuxDebug() -> Bool {
        #if os(Linux) && DEBUG
        return true
        #else
        return false
        #endif
    }
    
    
    static var productsDirectory: URL {
        let bundle = Bundle(for: Self.self)
        #if os(macOS)
        return bundle.bundleURL.deletingLastPathComponent()
        #else
        return bundle.bundleURL
        #endif
    }
    
    
    static func urlOfBuildProduct(named productName: String) -> URL {
        productsDirectory.appendingPathComponent(productName)
    }
    
    
    /// A utility function which attempts to read the source root.
    /// Note that this function should only be invoked from withing a running test case.
    /// If this function is unable to fetch the source root, it will call `XCTFail` and abort.
    static func tryGetApodiniSrcRootUrl() -> URL {
        guard let srcRoot = ProcessInfo.processInfo.environment["LKApodiniSrcRoot"] else {
            XCTFail("Unable to read source root")
            fatalError() // should be unreachable???
        }
        return URL(fileURLWithPath: srcRoot)
    }
    
    
    static func createTestWebServiceDirStructure() throws -> URL {
        
        let fileManager = FileManager()
        
//        guard let locatorPath = Bundle.module.url(forResource: "locator", withExtension: "txt") else {
//            throw ApodiniDeployError(message: "Unable to locate locator file")
//        }
//
//        print("LOCATOR", locatorPath)
//
//        let testWebServiceUrlInBundle = bundleResourcesUrl
//            .appendingPathComponent("Resources", isDirectory: true)
//            .appendingPathComponent("ADTestWebService", isDirectory: true)
        
        guard let testWebServiceUrlInBundle = Bundle.module.url(forResource: "ADTestWebService", withExtension: nil) else {
            throw ApodiniDeployError(message: "Unable to locate 'ADTestWebService' in bundle.")
        }
        
        let testWebServiceUrlInTmpDir = fileManager.temporaryDirectory
            .appendingPathComponent("ADT_\(UUID().uuidString)", isDirectory: true)
        
//        try fileManager.createDirectory(
//            at: testWebServiceUrlInTmpDir,
//            withIntermediateDirectories: true,
//            attributes: [:]
//        )
        print("\n\ncopy:\nSRC: \(testWebServiceUrlInBundle.absoluteURL.path)\nDST: \(testWebServiceUrlInTmpDir.absoluteURL.path)")
        try fileManager.copyItem(at: testWebServiceUrlInBundle, to: testWebServiceUrlInTmpDir)
        
        return testWebServiceUrlInTmpDir
    }
}


// MARK: XCT Utils

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
