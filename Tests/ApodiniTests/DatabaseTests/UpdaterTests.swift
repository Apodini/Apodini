import Foundation
@testable import Apodini
@testable import ApodiniDatabase
import XCTApodini


final class UpdaterTests: ApodiniTests {
    func testSingleParameterUpdater() throws {
        let bird = Bird(name: "Mockingbird", age: 20)
        let dbBird = try bird
            .save(on: self.app.database)
            .transform(to: bird)
            .wait()
        
        XCTAssertNotNil(dbBird.id)
        
        struct UpdaterTestsHandler: Handler {
            @Environment(\.database)
            var database: Database
            
            @Parameter
            var name: String
            
            func handle() -> EventLoopFuture<[Bird]> {
                Bird.query(on: database).all()
            }
        }
        
        let updatedBird = Bird(name: "Bird", age: 20)
        
        try XCTCheckHandler(
            UpdaterTestsHandler(),
            application: self.app,
            request: MockExporterRequest(on: self.app.eventLoopGroup.next(), "Bird"),
            status: .created,
            content: updatedBird
        )
        
        XCTFail()

//        dbBird.updateFields(withProperties: <#T##[String : Property]#>)
//
//        let updater = Updater<Bird>(parameters, model: nil, modelId: id)
//        let testDatabase = try database()
//        let result = try updater.executeUpdate(on: testDatabase).wait()
//        XCTAssert(result.id == dbBird.id)
//        XCTAssert(result.name == "FooBird")
    }
    
    func testModelUpdater() throws {
        XCTFail()
        
//        let bird = Bird(name: "Mockingbird", age: 20)
//        let dbBird = try bird
//            .save(on: self.app.database)
//            .transform(to: bird)
//            .wait()
//        XCTAssertNotNil(dbBird.id)
//
//        let newBird = Bird(name: "FooBird", age: 6)
//
//        guard let id = dbBird.id else {
//            return
//        }
//
//        let updater = Updater<Bird>([:], model: newBird, modelId: id)
//        let testDatabase = try database()
//        let result = try updater.executeUpdate(on: testDatabase).wait()
//        XCTAssert(result == newBird)
    }
}
