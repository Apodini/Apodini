import Foundation
import XCTest
import Fluent
@testable import ApodiniDatabase

final class UpdaterTests: ApodiniTests {
    func testSingleParameterUpdater() throws {
        
        let bird = Bird(name: "Mockingbird", age: 20)
        let dbBird = try bird
            .save(on: self.app.db)
            .transform(to: bird)
            .wait()
        XCTAssertNotNil(dbBird.id)
        
        let parameters: [String: TypeContainer] = [
            "name": TypeContainer(with: "FooBird")
        ]
        
        guard let id = dbBird.id else {
            return
        }
        
        let updater = Updater<Bird>(parameters, model: nil, modelId: id)
        let db = try database()
        let result = try updater.executeUpdate(on: db).wait()
        XCTAssert(result.id == dbBird.id)
        XCTAssert(result.name == "FooBird")
    }
    
    func testModelUpdater() throws {
        
        let bird = Bird(name: "Mockingbird", age: 20)
        let dbBird = try bird
            .save(on: self.app.db)
            .transform(to: bird)
            .wait()
        XCTAssertNotNil(dbBird.id)
        
        let newBird = Bird(name: "FooBird", age: 6)
        
        guard let id = dbBird.id else {
            return
        }
        
        let updater = Updater<Bird>(nil, model: newBird, modelId: id)
        let db = try database()
        let result = try updater.executeUpdate(on: db).wait()
        XCTAssert(result == newBird)
    }
}
