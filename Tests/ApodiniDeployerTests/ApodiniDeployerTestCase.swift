//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation
import XCTApodini
@testable import ApodiniDeployer
import ApodiniUtils


/// The base class for all test cases which test Deployment Providers.
/// This class intentionally does not inherit from `XCTApodiniTest`, the reason being that
/// that class creates an implicit `Apodini.Application`, which we do not need when testing the Deployment Providers.
class ApodiniDeployerTestCase: XCTestCase {
    struct ApodiniDeployerTestError: Swift.Error {
        let message: String
    }
    
    /// Name of the test web service target (used by e.g. the web service exporter tests).
    /// Note that this is **not** the web service in the Tests/ApodiniDeployer/Resources folder, but the target in Sources/ApodiniDeployerTestWebService
    static let ApodiniDeployerTestWebServiceTargetName = "ApodiniDeployerTestWebService"
    
    /// Url of the test web service's executable, as compiled by SPM or Xcode
    static var ApodiniDeployerTestWebServiceTargetUrl: URL {
        urlOfBuildProduct(named: ApodiniDeployerTestWebServiceTargetName)
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
        #if os(macOS) && !Xcode
        return true
        #else
        return false
        #endif
    }
    
    
    static func urlOfBuildProduct(named productName: String) -> URL {
        productsDirectory.appendingPathComponent(productName)
    }
    
    
    private static var cachedTmpDirSrcRoot: URL?
    
    /// Copies the entire Apodini source code into a temporary directory.
    /// This can be used for testing Deployment Providers, which usually require
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
        let expectedTrailingComponents = ["Tests", "ApodiniDeployerTests", "ApodiniDeployerTestCase.swift"]
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
        ApodiniDeployerTestError(message: message)
    }
}
