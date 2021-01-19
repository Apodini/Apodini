struct Bird: Codable {
    var name: String
    var age: Int
}

extension Bird {
    static func == (lhs: Bird, rhs: Bird) -> Bool {
        lhs.name == rhs.name && lhs.age == rhs.age
    }
}
