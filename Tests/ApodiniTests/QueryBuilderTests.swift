import Foundation
import XCTest
import Fluent
@testable import ApodiniDatabase

final class QueryBuilderTests: ApodiniTests {
    func testQueryString() throws {
        let queryString = "http://localhost:8080/v1/api/birds/birds?name=Swift&age=5"
        
        let expectedParameters: [FieldKey: TypeContainer] = [
            Bird.fieldKey(for: "name"): TypeContainer(with: "Swift"),
            Bird.fieldKey(for: "age"):  TypeContainer(with: "5")
        ]
        let queryBuilder = QueryBuilder(type: Bird.self, parameters: expectedParameters)
        
        let birds = try queryBuilder.execute(on: app.db).wait()
        XCTAssert(birds.count == 1)
        XCTAssert(birds[0].name == "Swift")
        
        let info = QueryBuilder.info(for: Bird.self)
        let expectedInfo: [ModelInfo] = [
//            ModelInfo(key: Bird.fieldKey(for: "id"), value: AnyCo(UUID.self, key: Bird.fieldKey(for: "id"))),
//            ModelInfo(key: Bird.fieldKey(for: "name"), value: AnyGenericCodable(String.self, key: Bird.fieldKey(for: "name"))),
//            ModelInfo(key: Bird.fieldKey(for: "age"), value: AnyGenericCodable(Int.self, key: Bird.fieldKey(for: "age")))
        ]
        XCTAssertEqual(info, expectedInfo, "Expected: \(expectedInfo)\n Found: \(info)")
    }
}
