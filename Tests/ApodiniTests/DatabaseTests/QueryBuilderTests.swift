//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation
import XCTest
@testable import ApodiniDatabase

final class QueryBuilderTests: ApodiniTests {
    func testQueryString() throws {
        let expectedParameters: [FieldKey: TypeContainer] = [
            Bird.fieldKey(for: "name"): TypeContainer(with: "Swift"),
            Bird.fieldKey(for: "age"): TypeContainer(with: "5")
        ]
        let queryBuilder = QueryBuilder(type: Bird.self, parameters: expectedParameters)
        
        let birds = try queryBuilder.execute(on: app.database).wait()
        XCTAssert(birds.count == 1)
        XCTAssert(birds[0].name == "Swift")
        XCTAssert(birds[0].age == 5)
    }
}
