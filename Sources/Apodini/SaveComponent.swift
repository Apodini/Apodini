import NIO


protocol Bird {
    var name: String { get }
    var age: Int { get }
}


struct Swift: Bird, Codable {
    let name: String
    let age: Int
}

struct User {
    let username: String
    let password: String
}

@propertyWrapper
struct RequestUser {
    var wrappedValue: User
    
    init() {
        fatalError("Not implemented")
    }
}

struct Database {
    let version: Int
}

@propertyWrapper
struct CurrentDatabase {
    var wrappedValue: Database
    
    init() {
        fatalError("Not implemented")
    }
}

@propertyWrapper
struct Body<Element: Codable> {
    var wrappedValue: Element
    
    init() {
        fatalError("Not implemented")
    }
}

// Question: How would I construct the property wrapper so the whole SaveSwiftComponent can be
//           instanciated with one Request and the properties are all filled in.
struct SaveSwiftComponent: Component {
    @RequestUser
    var user: User
    
    @CurrentDatabase
    var database: Database
    
    @Body
    var swift: Swift
    
    func handle(_ request: Request) -> EventLoopFuture<Swift> {
        // ... save to database and check it user is authorized to save a swift bird
        request.eventLoop.makeSucceededFuture(swift)
    }
}

// Ideal:
// let request = Request()
// let saveSwiftComponent = SaveSwiftComponent(request: request)
// saveSwiftComponent.handle(request)
