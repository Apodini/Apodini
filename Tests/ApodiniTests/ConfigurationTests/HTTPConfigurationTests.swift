//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import XCTApodini
import ApodiniHTTP
@testable import Apodini
import XCTApodiniNetworking
import Foundation


class HTTPConfigurationTests: XCTApodiniTest {
    func testCustomRootPrefixRequest() throws {
        var configuration: Configuration {
            HTTP(rootPath: "prefix")
        }

        @ComponentBuilder
        var content: some Component {
            Group("test") {
                Text("Paul")
            }
        }
        
        app.storage[VersionStorageKey.self] = Version()
        
        configuration.configure(app)
        let visitor = SyntaxTreeVisitor(modelBuilder: SemanticModelBuilder(app))
        content.accept(visitor)
        visitor.finishParsing()
        
        try app.testable().test(.GET, "/prefix/test") { response in
            XCTAssertEqual(response.status, .ok)
            XCTAssertEqual(try response.bodyStorage.getFullBodyData(decodedAs: String.self, using: JSONDecoder()), "Paul")
        }
    }
    
    func testVersionPrefixRequest() throws {
        var configuration: Configuration {
            HTTP(rootPath: .version)
        }

        @ComponentBuilder
        var content: some Component {
            Group("test") {
                Text("Paul")
            }
        }
        
        app.storage[VersionStorageKey.self] = Version(prefix: "p", major: 3, minor: 2, patch: 1)
        
        configuration.configure(app)
        let visitor = SyntaxTreeVisitor(modelBuilder: SemanticModelBuilder(app))
        content.accept(visitor)
        visitor.finishParsing()
        
        try app.testable().test(.GET, "/p3/test") { response in
            XCTAssertEqual(response.status, .ok)
            XCTAssertEqual(try response.bodyStorage.getFullBodyData(decodedAs: String.self, using: JSONDecoder()), "Paul")
        }
    }
}
