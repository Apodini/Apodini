import XCTest
import NIO
@testable import Apodini


final class CustomComponentTests: XCTestCase {
    struct Bird: Model, Codable {
        static var tableName: String = "Birds"
        
        let name: String
        let age: Int
    }
    
    struct BirdDatabase: Database {
        func fetch<M>(on eventLoop: EventLoop) -> EventLoopFuture<[M]> where M: Model {
            precondition(M.self is Bird.Type, "Sorry, the BirdDatabase can only fetch Birds 🦅")
            return eventLoop.makeSucceededFuture([Bird(name: "Swift", age: 5)] as! Array<M>)
        }
    }

    // Question: How would I construct the property wrapper so the whole SaveSwiftComponent can be
    //           instanciated with one Request and the properties are all filled in.
    struct GetBirdsComponent: Component {
        @RequestUser
        var user: User
        
        @CurrentDatabase
        var database: BirdDatabase
        
        @Body
        var bird: Bird
        
        
        func handle(_ request: Request) -> EventLoopFuture<[Bird]> {
            database.fetch(on: request.eventLoop)
        }
    }
    
    
    func testComponentCreation() {
        // Ideal:
        // let request = Request()
        // let saveSwiftComponent = SaveSwiftComponent(request: request)
        // saveSwiftComponent.handle(request)
    }
}
