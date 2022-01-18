//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

@testable import Apodini
import XCTApodini
import XCTest
import ApodiniUtils


/// A simple `Configuration` which simply executes a block
private struct BlockBasedConfiguration: Configuration {
    private let block: () -> Void
    
    init(_ block: @escaping () -> Void) {
        self.block = block
    }
    
    func configure(_ app: Application) {
        block()
    }
}


class ConditionalConfigurationTests: ApodiniTests {
    func testSimpleBuiltinCondition() {
        let flag1 = Box(false)
        let flag2 = Box(false)
        let flag3 = Box(false)
        let flag4 = Box(false)
        
        @ConfigurationBuilder
        var configuration: Configuration {
            BlockBasedConfiguration { flag1.value = true }
                .skip(if: .isHTTPSEnabled)
            BlockBasedConfiguration { flag2.value = true }
                .skip(if: !.isHTTPSEnabled)
            BlockBasedConfiguration { flag3.value = true }
                .enable(if: .isHTTPSEnabled)
            BlockBasedConfiguration { flag4.value = true }
                .enable(if: !.isHTTPSEnabled)
        }
        configuration.configure(app)
        
        XCTAssertEqual(flag1.value, true)
        XCTAssertEqual(flag2.value, false)
        XCTAssertEqual(flag3.value, false)
        XCTAssertEqual(flag4.value, true)
    }
    
    
    func testCustomCondition() {
        let randBool = Bool.random()
        let flag = Box(false)
        
        @ConfigurationBuilder
        var configuration: Configuration {
            BlockBasedConfiguration { flag.value = true }
                .skip(if: { randBool })
        }
        configuration.configure(app)
        
        XCTAssertEqual(flag.value, !randBool)
    }
    
    
    func testCompositeConditions() {
        let flag1 = Box(false)
        let flag2 = Box(false)
        let flag3 = Box(false)
        let flag4 = Box(false)
        
        @ConfigurationBuilder
        var configuration: Configuration {
            BlockBasedConfiguration { flag1.value = true }
                .enable(if: !.isHTTPSEnabled && .isDebugBuild)
            BlockBasedConfiguration { flag2.value = true }
                .enable(if: !.isHTTPSEnabled || .isDebugBuild)
            BlockBasedConfiguration { flag3.value = true }
                .enable(if: !.isHTTPSEnabled && .isReleaseBuild)
            BlockBasedConfiguration { flag4.value = true }
                .enable(if: (.isDebugBuild && .isArch(.arm64) || (.isReleaseBuild && .isOS(.linux))))
        }
        configuration.configure(app)
        
        #if DEBUG
        XCTAssertEqual(flag1.value, true)
        XCTAssertEqual(flag3.value, false)
        #else
        XCTAssertEqual(flag1.value, false)
        XCTAssertEqual(flag3.value, true)
        #endif
        XCTAssertEqual(flag2.value, true)
        #if (DEBUG && arch(arm64)) || (!DEBUG && os(Linux))
        XCTAssertEqual(flag4.value, true)
        #else
        XCTAssertEqual(flag4.value, false)
        #endif
    }
}
