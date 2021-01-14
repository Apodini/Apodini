import Apodini
import XCTest
@testable import Notifications

final class DatabaseConfigurationTests: XCTestCase {
    // swiftlint:disable implicitly_unwrapped_optional
    var app: Application!

    override func setUp() {
        super.setUp()
        self.app = Application()
    }

    override func tearDown() {
        app.shutdown()
        super.tearDown()
    }

    func testDatabaseSetup() throws {
        DatabaseConfiguration(.sqlite(.memory))
            .addNotifications()
            .configure(self.app)
        XCTAssertNotNil(app.databases.configuration())
    }
}
