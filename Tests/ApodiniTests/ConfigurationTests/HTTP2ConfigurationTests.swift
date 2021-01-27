@testable import Apodini
import NIOSSL
import XCTest

final class HTTP2ConfigurationTests: ApodiniTests {
    let currentPath = URL(fileURLWithPath: #file).deletingLastPathComponent().path
    lazy var keyPath: String = currentPath + "/Certificates/key.pem"
    lazy var key2Path: String = currentPath + "/Certificates/key2.pem"
    lazy var certPath: String = currentPath + "/Certificates/cert.pem"
    lazy var privateKey = NIOSSLPrivateKeySource.file(keyPath)

    func testValidFile() throws {
        HTTP2Configuration()
            .certificate(certPath)
            .key(keyPath)
            .configure(app)

        XCTAssertNotNil(app.http.tlsConfiguration)
        XCTAssertEqual(app.http.supportVersions, [.one, .two])
        XCTAssertEqual(app.http.tlsConfiguration?.privateKey, privateKey)
    }


    func testCommandLineArguments() throws {
        HTTP2Configuration(arguments: CommandLine.arguments + ["--cert", certPath, "--key", keyPath])
            .configure(app)

        XCTAssertNotNil(app.http.tlsConfiguration)
        XCTAssertEqual(app.http.supportVersions, [.one, .two])
        XCTAssertEqual(app.http.tlsConfiguration?.privateKey, privateKey)
    }

    func testCommandLineArgumentOverwrite() throws {
        HTTP2Configuration(arguments: CommandLine.arguments + ["--cert", certPath, "--key", keyPath])
            .certificate(certPath)
            .key(key2Path)
            .configure(app)

        XCTAssertNotNil(app.http.tlsConfiguration)
        XCTAssertEqual(app.http.supportVersions, [.one, .two])
        XCTAssertEqual(app.http.tlsConfiguration?.privateKey, privateKey)
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
