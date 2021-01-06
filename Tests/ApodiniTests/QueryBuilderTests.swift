import Foundation
import XCTest
import Fluent
@testable import ApodiniDatabase

final class QueryBuilderTests: ApodiniTests {
    func testQueryString() throws {
        let queryString = "http://localhost:8080/v1/api/birds/birds?name=Swift&age=5"
        let queryBuilder = QueryBuilder(type: Bird.self, queryString: queryString)
        
        let expectedParameters = [
            Bird.fieldKey(for: "name"): "Swift",
            Bird.fieldKey(for: "age"): "5"
        ]
        XCTAssertEqual(queryBuilder.parameters, expectedParameters, "Expected: \(expectedParameters)\n Found: \(queryBuilder.parameters)")
        
        let birds = try queryBuilder.execute(on: app.db).wait()
        XCTAssert(birds.count == 1)
        XCTAssert(birds[0].name == "Swift")
        
        let info = QueryBuilder.info(for: Bird.self)
        let expectedInfo: [ModelInfo] = [
            ModelInfo(key: Bird.fieldKey(for: "id"), type: UUID.self),
            ModelInfo(key: Bird.fieldKey(for: "name"), type: String.self),
            ModelInfo(key: Bird.fieldKey(for: "age"), type: Int.self)
        ]
        XCTAssertEqual(info, expectedInfo, "Expected: \(expectedInfo)\n Found: \(info)")
    }
}
