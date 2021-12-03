import Foundation

/// A helper type conforming to `CodingKey` that does not support string-based coding keys,
/// and will always return the same `intValue`.
struct FixedCodingKey: CodingKey {
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