//
//  CustomCompoentTest.swift
//
//
//  Created by Paul Schmiedmayer on 6/27/20.
//

import XCTest
import NIO
@testable import Apodini


final class CustomComponentTests: XCTestCase {
    struct Bird: Model, Equatable, Codable {
        static var tableName: String = "Birds"
        
        let id: Int
        let name: String
        let age: Int
    }
    
    class BirdDatabase: Database {
        var birds: [Bird] = [
            Bird(id: 1, name: "Swift", age: 5)
        ]
        
        func store<M>(_ model: M, on eventLoop: EventLoop) -> EventLoopFuture<M> where M : Model {
            guard let model = model as? Bird else {
                fatalError("Sorry, the BirdDatabase can only store Birds 🦅")
            }
            
            birds.append(model)
            return eventLoop.makeSucceededFuture(model as! M)
        }
        
        func fetch<M>(on eventLoop: EventLoop) -> EventLoopFuture<[M]> where M: Model {
            precondition(M.self is Bird.Type, "Sorry, the BirdDatabase can only fetch Birds 🦅")
            return eventLoop.makeSucceededFuture(birds as! Array<M>)
        }
    }

    struct AddBirdsComponent: Component {
        @CurrentDatabase
        var database: BirdDatabase
        
        @Body
        var bird: Bird
        
        
        func handle(_ request: Request) -> EventLoopFuture<[Bird]> {
            database.store(bird, on: request.eventLoop)
                .flatMap { _ in
                    database.fetch(on: request.eventLoop)
                }
        }
    }
    
    
    var context = Context(database: BirdDatabase(),
                          eventLoop: EmbeddedEventLoop())
    
    
    func testComponentCreation() throws {
        let bird = Bird(id: 2, name: "New", age: 0)
        let birdData = ByteBuffer(data: try JSONEncoder().encode(bird))
        
        let request = Request(body: birdData, context: context)
        
        let addBirdsComponent = AddBirdsComponent()
        let birds = try addBirdsComponent
            .handleInContext(of: request)
            .wait()
            
        XCTAssert(birds.count == 2)
        XCTAssert(birds[1] == bird)
    }
}
