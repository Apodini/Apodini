import XCTest
import protocol FluentKit.Database
import XCTApodini
@testable import Apodini

final class DatabaseEnvironmentTests: XCTApodiniDatabaseBirdTest {
    struct DatabaseComponent: Handler {
        @Apodini.Environment(\.database) var database: Database
        
        func handle() -> String {
            database.history.debugDescription
        }
    }
    
    func testEnvironmentInjection() throws {
        try XCTCheckHandler(DatabaseComponent()) {
            MockRequest(expectation: app.database.history.debugDescription)
        }
    }
}
