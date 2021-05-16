@testable import ApodiniDatabase
import XCTApodini


final class DatabaseHandlerTests: XCTApodiniDatabaseBirdTest {
    func testCreateHandler() throws {
        let bird = Bird(name: "Mockingbird", age: 20)
        
        let creationHandler = Create<Bird>()
        
        
        let response = try XCTUnwrap(
            try XCTCheckHandler(creationHandler) {
                MockRequest(expectation: .response(status: .created, bird)) {
                    UnnamedParameter(bird)
                }
            }
        )
        
        let foundBird = try XCTUnwrap(Bird.find(response.id, on: app.database).wait())
        XCTAssertEqual(response, foundBird)
    }
    
    func testCreateAllHandler() throws {
        let bird = Bird(name: "Mockingbird", age: 20)
        let bird2 = Bird(name: "Hummingbird", age: 25)
        
        let creationHandler = CreateAll<Bird>()
        
        let response = try XCTUnwrap(
            try XCTCheckHandler(creationHandler) {
                MockRequest<[Bird]>(expectation: .status(.created)) {
                    UnnamedParameter([bird, bird2])
                }
            }
        )
        
        XCTAssert(!response.isEmpty)
        XCTAssert(response.contains(bird))
        XCTAssert(response.contains(bird2))
        
        let foundBird1 = try XCTUnwrap(try Bird.find(response[0].id, on: app.database).wait())
        XCTAssert(response.contains(foundBird1))
        
        let foundBird2 = try XCTUnwrap(try Bird.find(response[1].id, on: app.database).wait())
        XCTAssert(response.contains(foundBird2))
    }
    
    func testSingleReadHandler() throws {
        let bird = Bird(name: "Mockingbird", age: 20)
        let dbBird = try bird
            .save(on: self.app.database)
            .transform(to: bird)
            .wait()
        let birdId = try XCTUnwrap(dbBird.id)
        
        try XCTCheckHandler(ReadOne<Bird>()) {
            MockRequest(expectation: dbBird) {
                NamedParameter("id", value: birdId)
            }
        }
    }
    
    func testReadHandler() throws {
        let bird1 = Bird(name: "Mockingbird", age: 20)
        let dbBird1 = try bird1
            .save(on: self.app.database)
            .transform(to: bird1)
            .wait()
        
        let bird2 = Bird(name: "Mockingbird", age: 21)
        let dbBird2 = try bird2
            .save(on: self.app.database)
            .transform(to: bird2)
            .wait()
        
        XCTAssertNotNil(dbBird1.id)
        XCTAssertNotNil(dbBird2.id)
        
        
        let response = try XCTUnwrap(
            XCTCheckHandler(ReadAll<Bird>()) {
                MockRequest<[Bird]> {
                    NamedParameter("name", value: "Mockingbird")
                }
            }
        )
        
        XCTAssert(response.count == 2)
        XCTAssert(response[0].name == "Mockingbird", response.debugDescription)
        XCTAssert(response[1].name == "Mockingbird", response.debugDescription)
        
        
        try XCTCheckHandler(ReadAll<Bird>()) {
            MockRequest(expectation: [Bird(name: "Mockingbird", age: 21)]) {
                NamedParameter("name", value: "Mockingbird")
                NamedParameter("age", value: 21)
            }
        }
        
        let bird1Id = try XCTUnwrap(dbBird1.id)
        
        try XCTCheckHandler(ReadAll<Bird>()) {
            MockRequest(expectation: [bird1]) {
                NamedParameter("id", value: bird1Id)
            }
        }
        
        try XCTCheckHandler(ReadAll<Bird>()) {
            MockRequest<[Bird]> {
                NamedParameter("name", value: "Mockingbird")
                NamedParameter("age", value: 22)
            }
        }
    }
    
    func testUpdateHandleWithSingleParameter() throws {
        let bird = Bird(name: "Mockingbird", age: 20)
        let dbBird = try bird
            .save(on: self.app.database)
            .transform(to: bird)
            .wait()
        let dbBirdId = try XCTUnwrap(dbBird.id)
        
        try XCTCheckHandler(Update<Bird>()) {
            MockRequest(expectation: .response(status: .ok, Bird(name: "Swift", age: 20))) {
                UnnamedParameter(dbBirdId)
                NamedParameter("name", value: "Swift")
            }
        }
        
        let updatedBird = try XCTUnwrap(Bird.find(dbBird.id, on: self.app.database).wait())
        XCTAssertEqual(updatedBird, Bird(name: "Swift", age: 20))
    }
    
    func testUpdateHandlerWithModel() throws {
        let bird = Bird(name: "Mockingbird", age: 20)
        let dbBird = try bird
            .save(on: self.app.database)
            .transform(to: bird)
            .wait()
        let dbBirdId = try XCTUnwrap(dbBird.id)
        
        let newBird = Bird(name: "FooBird", age: 25)
        
        try XCTCheckHandler(Update<Bird>()) {
            MockRequest(expectation: .response(status: .ok, newBird)) {
                UnnamedParameter(dbBirdId)
                UnnamedParameter(newBird)
            }
        }
        
        let updatedBird = try XCTUnwrap(Bird.find(dbBird.id, on: self.app.database).wait())
        XCTAssertEqual(updatedBird, newBird)
    }
    
    func testDeleteHandler() throws {
        let bird = Bird(name: "Mockingbird", age: 20)
        let dbBird = try bird
            .save(on: self.app.database)
            .transform(to: bird)
            .wait()
        
        let dbBirdId = try XCTUnwrap(dbBird.id)
        
        try XCTCheckHandler(Delete<Bird>()) {
            MockRequest(expectation: .status(.noContent)) {
                UnnamedParameter(dbBirdId)
            }
        }
        
        let deletedBird = try Bird.find(dbBird.id, on: app.database).wait()
        XCTAssertNil(deletedBird)
    }
}
