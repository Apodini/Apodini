import Foundation
import XCTest
import Fluent
@testable import ApodiniDatabase

final class UpdaterTests: ApodiniTests {
    func testSingleParameterUpdater() throws {
        let bird = Bird(name: "Mockingbird", age: 20)
        let databaseBird = try bird
            .save(on: self.app.database)
            .transform(to: bird)
            .wait()
        XCTAssertNotNil(databaseBird.id)
        
        let parameters: [String: TypeContainer] = [
            "name": TypeContainer(with: "FooBird")
        ]
        
        guard let id = databaseBird.id else {
            return
        }
        
        let updater = Updater<Bird>(parameters, model: nil, modelId: id)
        let testDatabase = try database()
        let result = try updater.executeUpdate(on: testDatabase).wait()
        XCTAssert(result.id == databaseBird.id)
        XCTAssert(result.name == "FooBird")
    }
    
    func testModelUpdater() throws {
        let bird = Bird(name: "Mockingbird", age: 20)
        let databaseBird = try bird
            .save(on: self.app.database)
            .transform(to: bird)
            .wait()
        XCTAssertNotNil(databaseBird.id)
        
        let newBird = Bird(name: "FooBird", age: 6)
        
        guard let id = databaseBird.id else {
            return
        }
        
        let updater = Updater<Bird>([:], model: newBird, modelId: id)
        let testDatabase = try database()
        let result = try updater.executeUpdate(on: testDatabase).wait()
        XCTAssert(result == newBird)
    }
}
