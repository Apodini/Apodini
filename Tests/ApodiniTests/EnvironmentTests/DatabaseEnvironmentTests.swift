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
        let component = DatabaseComponent()
        let response = try XCTUnwrap(mockQuery(handler: component, value: String.self, app: app))
        
        let description = try database().history.debugDescription
        //not ideal to compare history description, but fluent database does not provide an id.
        XCTAssert(app.database.history.debugDescription == description)
        XCTAssert(response == description)
    }
}
