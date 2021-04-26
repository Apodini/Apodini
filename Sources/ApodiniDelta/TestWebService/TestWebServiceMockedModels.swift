import Foundation
import Apodini


struct Course: Content {
    let id: UUID
    let title: String
    let topics: [String]
    let price: Double
    
    init() {
        id = UUID()
        title = "Swift-Bootcamp"
        topics = ["Basics", "Advanced"]
        price = 99.99
    }
}

struct User: Content {
    let id: Int
    let name: String
    let surname: String
    let courses: [Course]
    
    init() {
        id = 1
        name = "Swiftler"
        surname = "Smith"
        courses = [Course()]
    }
}

struct UsersHandler: Handler {
    func handle() throws -> [User] {
        [User()]
    }
}

struct UserHandler: Handler {
    @Parameter(.http(.path)) var id: Int
    
    func handle() throws -> User {
        User()
    }
}


struct CoursesHandler: Handler {
    func handle() throws -> [Course] {
        [Course()]
    }
}

struct CourseHandler: Handler {
    @Parameter(.http(.path)) var id: UUID
    
    func handle() throws -> Course {
        Course()
    }
}
