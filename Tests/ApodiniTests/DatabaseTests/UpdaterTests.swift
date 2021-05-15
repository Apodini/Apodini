@testable import ApodiniDatabase
import XCTApodini


final class UpdaterTests: XCTApodiniDatabaseBirdTest {
    func testSingleParameterUpdater() throws {
        let bird = Bird(name: "Mockingbird", age: 20)
        let dbBird = try bird
            .save(on: self.app.database)
            .transform(to: bird)
            .wait()
        
        XCTAssertNotNil(dbBird.id)
        
        XCTFail("Test case not yet updated")
//        let parameters: [String: TypeContainer] = [
//            "name": TypeContainer(with: "FooBird")
//        ]
//
//        guard let id = dbBird.id else {
//            return
//        }
//
//        let updater = Updater<Bird>(parameters, model: nil, modelId: id)
//        let testDatabase = try database()
//        let result = try updater.executeUpdate(on: testDatabase).wait()
//        XCTAssert(result.id == dbBird.id)
//        XCTAssert(result.name == "FooBird")
    }
    
    func testModelUpdater() throws {
        XCTFail("Test case not yet updated")
        
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
