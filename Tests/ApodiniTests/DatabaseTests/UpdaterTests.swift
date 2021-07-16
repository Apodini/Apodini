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

final class UpdaterTests: ApodiniTests {
    func testSingleParameterUpdater() throws {
        let bird = Bird(name: "Mockingbird", age: 20)
        let dbBird = try bird
            .save(on: self.app.database)
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
        let testDatabase = try database()
        let result = try updater.executeUpdate(on: testDatabase).wait()
        XCTAssert(result.id == dbBird.id)
        XCTAssert(result.name == "FooBird")
    }
    
    func testModelUpdater() throws {
        let bird = Bird(name: "Mockingbird", age: 20)
        let dbBird = try bird
            .save(on: self.app.database)
            .transform(to: bird)
            .wait()
        XCTAssertNotNil(dbBird.id)
        
        let newBird = Bird(name: "FooBird", age: 6)
        
        guard let id = dbBird.id else {
            return
        }
        
        let updater = Updater<Bird>([:], model: newBird, modelId: id)
        let testDatabase = try database()
        let result = try updater.executeUpdate(on: testDatabase).wait()
        XCTAssert(result == newBird)
    }
}
