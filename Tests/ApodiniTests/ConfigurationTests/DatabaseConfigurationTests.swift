@testable import Apodini
@testable import ApodiniDatabase
import XCTest

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
        DatabaseConfiguration(.sqlite(.memory), as: .sqlite)
            .configure(self.app)
        XCTAssertNotNil(app.databases.configuration())
    }
}
