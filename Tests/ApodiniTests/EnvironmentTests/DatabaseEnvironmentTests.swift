import XCTest
import protocol Fluent.Database
import XCTApodini
@testable import Apodini

final class DatabaseEnvironmentTests: ApodiniTests {
    struct DatabaseComponent: Handler {
        @Apodini.Environment(\.db) var database: Database
        
        func handle() -> String {
            database.history.debugDescription
        }
    }
    
    func testEnvironmentInjection() throws {
        let component = DatabaseComponent()
        let request = MockRequest.createRequest(on: component, running: app.eventLoopGroup.next())

        let response: String = request.enterRequestContext(with: component) { component in
            component.handle()
        }
        
        let description = try database().history.debugDescription
        //not ideal to compare history description, but fluent db does not provide an id.
        XCTAssert(app.db.history.debugDescription == description)
        XCTAssert(response == description)
    }
}
