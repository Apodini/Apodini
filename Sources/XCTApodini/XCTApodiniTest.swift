import XCTVapor
import FluentSQLiteDriver
import Apodini

open class XCTApodiniTest: XCTestCase {
    open lazy var app: Vapor.Application = Application(.testing)
    
    override open func setUpWithError() throws {
        try super.setUpWithError()
        
        app.shutdown()
        app = Application(.testing)
    }
    
    override open func tearDownWithError() throws {
        try super.tearDownWithError()
        
        let app = try XCTUnwrap(self.app)
        app.shutdown()
    }
    
    open func tester() throws -> XCTApplicationTester {
        try XCTUnwrap(app.testable())
    }
    
    open func addMigrations(_ migrations: Migration...) throws {
        let app = try XCTUnwrap(self.app)
        
        app.databases.use(
            .sqlite(.memory),
            as: .init(string: "ApodiniTest"),
            isDefault: true
        )
        
        app.migrations.add(migrations)
        
        try app.autoMigrate().wait()
    }
    
    open func database() throws -> Database {
        try XCTUnwrap(self.app.db)
    }
}
