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


final class TLSConfigurationTests: ApodiniTests {
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
        HTTPConfiguration(tlsConfigurationBuilder: TLSConfigurationBuilder(certificatePath: try certPath().path, keyPath: try keyPath().path))
            .configure(app)

        XCTAssertNotNil(app.httpConfiguration.tlsConfiguration)
        XCTAssertEqual(app.httpConfiguration.supportVersions, [.one, .two])
        XCTAssertEqual(app.httpConfiguration.tlsConfiguration?.privateKey, try privateKey())
    }
}
