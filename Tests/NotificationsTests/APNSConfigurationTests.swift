@testable import Notifications
import XCTest
import XCTApodini

class APNSConfigurationTests: XCTApodiniTest {
    let currentPath = URL(fileURLWithPath: #file).deletingLastPathComponent().path
    
    func testFailingConfiguration() throws {
        XCTAssertRuntimeFailure(APNSConfiguration(.pem(pemPath: ""), topic: "", environment: .sandbox).configure(self.app))
    }
    
    func testPEMConfiguration() throws {
        let path = currentPath + "/Helper/mock.pem"
        
        XCTAssertNoThrow(APNSConfiguration(.pem(pemPath: path), topic: "", environment: .sandbox).configure(app))
        XCTAssertNotNil(app.apns.configuration)
    }
    
    func testP8Configuration() throws {
        let path = currentPath + "/Helper/mock.p8"
        
        XCTAssertNoThrow(APNSConfiguration(.p8(path: path, keyIdentifier: "", teamIdentifier: ""), topic: "", environment: .sandbox).configure(app))
        XCTAssertNotNil(app.apns.configuration)
    }
}
