//
//  File.swift
//  
//
//  Created by Tim Gymnich on 14.1.21.
//

@testable import Apodini
import XCTest

class HTTP2ConfigurationTests: ApodiniTests {
    let currentPath = URL(fileURLWithPath: #file).deletingLastPathComponent().path

    func testValidFile() throws {
        let keyPath = currentPath + "/Certificates/key.pem"
        let certPath = currentPath + "/Certificates/cert.pem"

        HTTP2Configuration()
            .certificate(certPath)
            .key(keyPath)
            .configure(self.app)

        XCTAssertNotNil(app.http.tlsConfiguration)
        XCTAssertEqual(app.http.supportVersions, [.one, .two])
    }
}
