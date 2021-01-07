@testable import Notifications
import XCTest
import XCTApodini

class FCMConfigurationTests: XCTApodiniTest {
    let currentPath = URL(fileURLWithPath: #file).deletingLastPathComponent().path
    
    func testMissingFile() throws {
        XCTAssertRuntimeFailure(FCMConfiguration("something").configure(self.app), "FCM file doesn't exist at path: something")
    }
    
    func testMissingProperties() throws {
        let path = currentPath + "/Helper/mock_invalid_fcm.json"
        XCTAssertRuntimeFailure(FCMConfiguration(path).configure(self.app), "FCM unable to decode serviceAccount from file located at: \(path)")
    }
    
    func testValidFile() throws {
        let path = currentPath + "/Helper/mock_fcm.json"
        
        XCTAssertNoThrow(FCMConfiguration(path).configure(self.app))
        XCTAssertNotNil(app.fcm.configuration)
    }
}
