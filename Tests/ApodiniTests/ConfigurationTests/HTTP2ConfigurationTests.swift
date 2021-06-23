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
        HTTP2Configuration()
            .certificate(try certPath())
            .key(try keyPath())
            .configure(app)

        XCTAssertNotNil(app.http.tlsConfiguration)
        XCTAssertEqual(app.http.supportVersions, [.one, .two])
        XCTAssertEqual(app.http.tlsConfiguration?.privateKey, try privateKey())
    }
    
    func testCommandLineArguments() throws {
        HTTP2Configuration(cert: try certPath().path, keyPath: try keyPath().path)
            .configure(app)

        XCTAssertNotNil(app.http.tlsConfiguration)
        XCTAssertEqual(app.http.supportVersions, [.one, .two])
        XCTAssertEqual(app.http.tlsConfiguration?.privateKey, try privateKey())
    }
    
    func testCommandLineArgumentOverwrite() throws {
        HTTP2Configuration(cert: try certPath().path, keyPath: try keyPath().path)
            .certificate(try certPath())
            .key(try key2Path())
            .configure(app)

        XCTAssertNotNil(app.http.tlsConfiguration)
        XCTAssertEqual(app.http.supportVersions, [.one, .two])
        XCTAssertEqual(app.http.tlsConfiguration?.privateKey, try privateKey())
    }
}
