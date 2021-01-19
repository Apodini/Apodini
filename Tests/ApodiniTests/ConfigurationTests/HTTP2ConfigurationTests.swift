@testable import Apodini
import XCTest

final class HTTP2ConfigurationTests: ApodiniTests {
    let currentPath = URL(fileURLWithPath: #file).deletingLastPathComponent().path
    var keyPath: String { currentPath + "/Certificates/key.pem" }
    var certPath: String { currentPath + "/Certificates/cert.pem" }

    func testValidFile() throws {
        HTTP2Configuration()
            .certificate(certPath)
            .key(keyPath)
            .configure(self.app)

        XCTAssertNotNil(app.http.tlsConfiguration)
        XCTAssertEqual(app.http.supportVersions, [.one, .two])
    }


    func testCommandLineArguments() throws {
        HTTP2Configuration(arguments: CommandLine.arguments + ["--cert", certPath, "--key", keyPath])
            .configure(self.app)

        XCTAssertNotNil(app.http.tlsConfiguration)
        XCTAssertEqual(app.http.supportVersions, [.one, .two])
    }
}
