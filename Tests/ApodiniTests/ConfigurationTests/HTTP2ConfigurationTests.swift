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
        NIOSSLPrivateKeySource.file(try keyPath().path)
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
        HTTP2Configuration(arguments: CommandLine.arguments + ["--cert", try certPath().path, "--key", try keyPath().path])
            .configure(app)

        XCTAssertNotNil(app.http.tlsConfiguration)
        XCTAssertEqual(app.http.supportVersions, [.one, .two])
        XCTAssertEqual(app.http.tlsConfiguration?.privateKey, try privateKey())
    }

    func testCommandLineArgumentOverwrite() throws {
        HTTP2Configuration(arguments: CommandLine.arguments + ["--cert", try certPath().path, "--key", try keyPath().path])
            .certificate(try certPath())
            .key(try key2Path())
            .configure(app)

        XCTAssertNotNil(app.http.tlsConfiguration)
        XCTAssertEqual(app.http.supportVersions, [.one, .two])
        XCTAssertEqual(app.http.tlsConfiguration?.privateKey, try privateKey())
    }
}

extension NIOSSLPrivateKeySource: Equatable {
    public static func == (lhs: NIOSSLPrivateKeySource, rhs: NIOSSLPrivateKeySource) -> Bool {
        switch (lhs, rhs) {
        case let (.privateKey(lhsKey), .file(rhsFile)):
            // swiftlint:disable force_try
            let rhsKey = try! NIOSSLPrivateKey(file: rhsFile, format: .pem)
            return lhsKey == rhsKey
        case let (.file(lhsFile), .privateKey(rhsKey)):
            // swiftlint:disable force_try
            let lhsKey = try! NIOSSLPrivateKey(file: lhsFile, format: .pem)
            return lhsKey == rhsKey
        case let (.privateKey(lhsKey), .privateKey(rhsKey)) where lhsKey == rhsKey:
            return true
        case let (.file(lhsFile), .file(rhsFile)) where lhsFile == rhsFile:
            return true
        default:
            return false
        }
    }
}
