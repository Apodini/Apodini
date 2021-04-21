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
    override func tearDown() {
        super.tearDown()
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
}
