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


// MARK: XCT Utils

/// Asserts that two collections are equal (i.e. contain the same elements) ignoring the element's order,
func XCTAssertEqualIgnoringOrder<C0: Collection, C1: Collection>(_ lhs: C0, _ rhs: C1) where C0.Element == C1.Element, C0.Element: Hashable {
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
    XCTFail(msg)
}
