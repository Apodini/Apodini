@testable import Notifications
import XCTest
import XCTApodini

class FCMConfigurationTests: XCTApodiniTest {
    let currentPath = URL(fileURLWithPath: #file).deletingLastPathComponent()
    
    func testMissingFile() throws {
        XCTAssertRuntimeFailure(FCMConfiguration("something").configure(self.app), "FCM file doesn't exist at path: something")
    }
    
    func testMissingProperties() throws {
        let url = URL(string: "Helper/mock_invalid_fcm.json", relativeTo: currentPath)
        let path = try XCTUnwrap(url).path
        
        XCTAssertRuntimeFailure(FCMConfiguration(path).configure(self.app), "FCM unable to decode serviceAccount from file located at: \(path)")
    }
    
    func testValidFile() throws {
        let url = URL(string: "Helper/mock_fcm.json", relativeTo: currentPath)
        let path = try XCTUnwrap(url).path
        
        XCTAssertNoThrow(FCMConfiguration(path).configure(self.app))
        XCTAssertNotNil(app.fcm.configuration)
    }
}
