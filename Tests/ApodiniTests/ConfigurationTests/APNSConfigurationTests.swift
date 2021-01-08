@testable import Apodini
import XCTest
import XCTVapor

class APNSConfigurationTests: ApodiniTests {
    let currentPath = URL(fileURLWithPath: #file).deletingLastPathComponent().path
    
    func testFailingConfiguration() throws {
        XCTAssertRuntimeFailure(APNSConfiguration(.pem(pemPath: ""), topic: "", environment: .sandbox).configure(self.app))
    }
    
    func testPEMConfiguration() throws {
        let path = currentPath + "/mock.pem"
        
        XCTAssertNoThrow(APNSConfiguration(.pem(pemPath: path), topic: "", environment: .sandbox).configure(app))
        XCTAssertNotNil(app.apns.configuration)
    }
    
    func testP8Configuration() throws {
        let path = currentPath + "/mock.p8"
        
        XCTAssertNoThrow(APNSConfiguration(.p8(path: path, keyIdentifier: "", teamIdentifier: ""), topic: "", environment: .sandbox).configure(app))
        XCTAssertNotNil(app.apns.configuration)
    }
}
