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
    
    
    static var xctestBundle: Bundle {
        Bundle(for: Self.self)
    }
    
    
    static var productsDirectory: URL {
        xctestBundle.bundleURL.deletingLastPathComponent()
    }
    
    
    static func urlOfBuildProduct(named productName: String) -> URL {
        productsDirectory.appendingPathComponent(productName)
    }
}
