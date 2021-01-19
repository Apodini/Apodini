import XCTest
@testable import Apodini
import FluentSQLiteDriver

open class XCTApodiniTest: XCTestCase {
    // Vapor Application
    // swiftlint:disable implicitly_unwrapped_optional
    open var app: Application!
    
    override open func setUpWithError() throws {
        try super.setUpWithError()
        
        app = Application()
    }
    
    override open func tearDownWithError() throws {
        try super.tearDownWithError()
        
        app.shutdown()
        RHIInterfaceExporter.resetSingleton()
    }
    
    open func database() throws -> Database {
        try XCTUnwrap(self.app.db)
    }
    
    open func addMigrations(_ migrations: Migration...) throws {
        app.databases.use(
            .sqlite(.memory),
            as: .init(string: "ApodiniTest"),
            isDefault: true
        )
        
        app.migrations.add(migrations)
        
        try app.autoMigrate().wait()
    }
}
