protocol User {
    var username: String { get }
    var password: String { get }
}

@propertyWrapper
struct RequestUser {
    var wrappedValue: User
    
    init() {
        fatalError("Not implemented")
    }
}
