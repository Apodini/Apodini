import XCTest
import protocol Fluent.Database
import XCTApodini
@testable import Apodini

final class DatabaseEnvironmentTests: ApodiniTests {
    struct DatabaseComponent: Handler {
        @Apodini.Environment(\.database) var database: Database
        
        func handle() -> String {
            database.history.debugDescription
        }
    }
    
    func testEnvironmentInjection() throws {
        try XCTCheckHandler(
            DatabaseComponent(),
            application: self.app,
            content: app.database.history.debugDescription
        )
    }
}
