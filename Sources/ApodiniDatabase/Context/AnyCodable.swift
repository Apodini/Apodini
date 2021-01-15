import Foundation
import Fluent
//@testable import Apodini

struct AnyCodable: Codable {
    var wrappedValue: Codable? {
        didSet {
            wrappedType = .init(with: self)
        }
    }
    var wrappedType: TypeContainer?
    
    init(_ wrappedType: TypeContainer) {
        self.wrappedType = wrappedType
    }
    
    init(_ wrappedValue: Codable?) {
        setWrappedValue(wrappedValue)
    }

    private mutating func setWrappedValue(_ value: Codable?) {
        self.wrappedValue = value
    }
    
    public func encode(to encoder: Encoder) throws {
        try wrappedType?.encode(to: encoder)
    }
    
    public init(from decoder: Decoder) throws {
        self.init()
        wrappedType = try TypeContainer(from: decoder)
    }
    
    init() {
        wrappedValue = nil
        wrappedType = .noValue
    }
}

extension AnyCodable: LosslessStringConvertible {
    public init?(_ description: String) {
        self.init()
    }
    
    public var description: String {
        wrappedType?.description ?? wrappedValue.debugDescription
    }
}
