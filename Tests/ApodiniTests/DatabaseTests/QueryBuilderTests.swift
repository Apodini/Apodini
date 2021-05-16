@testable import Apodini
@testable import ApodiniDatabase
import Vapor
import XCTest


final class QueryBuilderTests: XCTApodiniDatabaseBirdTest {
    func testFieldPropertyQueryBuilder() throws {
        // ApodiniDatabase.QueryBuilder(MockModel.self, fieldKeys: MockModel)
        XCTFail()
    }
    
    func testIDPropertyVisitable() {
        let bird = Bird(name: "MockingBird", age: 25)
        let uuid = UUID()
        bird.id = uuid
        //let result = bird.$id.accept(ConcreteIDPropertyVisitor())
        //XCTAssertEqual(try XCTUnwrap(result.value as? UUID), uuid)
        XCTFail()
    }
    
    func testEnumPropertyVisitable() {
        XCTFail()
    }
    
    func testFieldPropertyUpdatable() throws {
        //let bird = Bird(name: "MockingBird", age: 25)
        //let newValueContainer: TypeContainer = .string("FooBird")
        //XCTAssertNoThrow(try bird.$name.accept(ConcreteUpdatableFieldPropertyVisitor(updater: newValueContainer)))
        //XCTAssert(bird.name == "FooBird")
        XCTFail()
    }
    
    func testQueryString() throws {
        //let expectedDatabaseInjectionContext: [FieldKeyProperty] = [
        //    FieldKeyProperty(key: FieldKey.string("name"), property: Apodini.Parameter<String>()),
        //    FieldKeyProperty(key: FieldKey.string("age"), property: Apodini.Parameter<Int>())
        //]
        
        //let queryBuilder = QueryBuilder(type: Bird.self, databaseInjectionContexts: expectedDatabaseInjectionContext)
        
        //let properties = expectedDatabaseInjectionContext
        
        //let birds = try queryBuilder.execute(on: app.database, properties: <#[String : Property]#>).wait()
        //XCTAssert(birds.count == 1)
        //XCTAssert(birds[0].name == "Swift")
        //XCTAssert(birds[0].age == 5)
        
        XCTFail()
    }
}
