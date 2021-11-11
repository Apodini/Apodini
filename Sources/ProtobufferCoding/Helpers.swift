import Foundation

struct FakeCodingKey: CodingKey {
    /// Guaranteed to be non-nil, but has to be nullable to satisfy the `CodingKey` protocol
    let intValue: Int?
    
    init(intValue: Int) {
        self.intValue = intValue
    }
    
    init?(stringValue: String) {
        fatalError()
    }
    var stringValue: String {
        fatalError()
    }
}
