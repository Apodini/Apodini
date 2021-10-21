//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

@testable import Apodini
import NIOSSL
import XCTest


final class HTTP2ConfigurationTests: ApodiniTests {
    private func keyPath() throws -> URL {
        try XCTUnwrap(Bundle.module.url(forResource: "key", withExtension: "pem"))
    }
    private func key2Path() throws -> URL {
        try XCTUnwrap(Bundle.module.url(forResource: "key2", withExtension: "pem"))
    }
    private func certPath() throws -> URL {
        try XCTUnwrap(Bundle.module.url(forResource: "cert", withExtension: "pem"))
    }
    private func privateKey() throws -> NIOSSLPrivateKeySource {
        try NIOSSLPrivateKeySource.privateKey(NIOSSLPrivateKey(file: keyPath().path, format: .pem))
    }
    
    
    func testValidFile() throws {
        HTTPConfiguration()
            .certificate(try certPath().path)
            .key(try keyPath().path)
            .configure(app)

        XCTAssertNotNil(app.httpConfiguration.tlsConfiguration)
        XCTAssertEqual(app.httpConfiguration.supportVersions, [.one, .two])
        XCTAssertEqual(app.httpConfiguration.tlsConfiguration?.privateKey, try privateKey())
    }
    
    func testCommandLineArguments() throws {
        HTTPConfiguration(cert: try certPath().path, key: try keyPath().path)
            .configure(app)

        XCTAssertNotNil(app.httpConfiguration.tlsConfiguration)
        XCTAssertEqual(app.httpConfiguration.supportVersions, [.one, .two])
        XCTAssertEqual(app.httpConfiguration.tlsConfiguration?.privateKey, try privateKey())
    }
    
    func testCommandLineArgumentOverwrite() throws {
        HTTPConfiguration(cert: try certPath().path, key: try keyPath().path)
            .certificate(try certPath().path)
            .key(try key2Path().path)
            .configure(app)

        XCTAssertNotNil(app.httpConfiguration.tlsConfiguration)
        XCTAssertEqual(app.httpConfiguration.supportVersions, [.one, .two])
        XCTAssertEqual(app.httpConfiguration.tlsConfiguration?.privateKey, try privateKey())
    }
}
