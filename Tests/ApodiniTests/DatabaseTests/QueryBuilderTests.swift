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
    }
}
