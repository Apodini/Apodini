//
//  OptionValue.swift
//
//
//  Created by Lukas Kollmer on 2021-02-06.
//

import Foundation


/// A type which can be used as an option's value
public protocol OptionValue: Codable {
    /// - Note: this operation should (must?) be commutative
    func reduce(with other: Self) -> Self
}




open class AnyOption<OuterNS: OuterNamespace>: Codable, Hashable, Equatable, CustomStringConvertible {
    public let key: AnyOptionKey<OuterNS>
    
    public init(key: AnyOptionKey<OuterNS>) {
        self.key = key
    }
    
    
    public var description: String {
        "\(Self.self)(key: \(key))"
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(key)
    }
    
    public static func == (lhs: AnyOption<OuterNS>, rhs: AnyOption<OuterNS>) -> Bool {
        lhs.key == rhs.key
    }
}



public final class ResolvedOption<OuterNS: OuterNamespace>: AnyOption<OuterNS> {
    private enum ValueStorage {
        case encoded(Data)
        case unencoded(value: Any, encodingFn: () throws -> Data)
    }
    
    enum CodingKeys: String, CodingKey {
        case key
        case encodedValue
    }
    
    
    private var valueStorage: ValueStorage
    private let reduceOptionsImp: (_ other: ResolvedOption<OuterNS>) -> ResolvedOption<OuterNS>
    
    
    public init<InnerNS, Value>(key: OptionKey<OuterNS, InnerNS, Value>, value: Value) {
        self.valueStorage = .unencoded(value: value, encodingFn: { try JSONEncoder().encode(value) })
        self.reduceOptionsImp = { otherOption in
            precondition(key == otherOption.key)
            print("oqoo")
            guard let otherValueUntyped = otherOption.untypedValue else {
                fatalError("Cannot reduce: Other option does not store an un-encoded value")
            }
            guard let otherValue = otherValueUntyped as? Value else {
                fatalError("Cannot reduce options with non-matching types ('\(Value.self)' vs '\(type(of: otherValueUntyped))').")
            }
            return ResolvedOption(key: key, value: value.reduce(with: otherValue))
        }
        super.init(key: key)
    }
    
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let key = try container.decode(AnyOptionKey<OuterNS>.self, forKey: .key)
        self.valueStorage = .encoded(try container.decode(Data.self, forKey: .encodedValue))
        self.reduceOptionsImp = { otherOption in
            fatalError("Cannot reduce this option because it was created using the 'init(Decoder)' initializer. Only \(Self.self) objects created using the 'init(key:, value:)' initializer can be reduced. (self.key: \(key), other.key: \(otherOption.key))")
//            precondition(optionA.key == key)
//            precondition(optionB.key == optionB.key)
//            print("fuck")
//            //ßreturn type(of: optionA.key).reduceOption(optionA, with: optionB)
//            //print("keys", AnyOptionKey.allKeys)
//            //guard let matchingKey = AnyOptionKey.allKeys.first(where: { $0 == optionA.key }) else {
//                Thread.callStackSymbols.forEach { print($0) }
//                fatalError("Cannot reduce this option because it was created using the 'init(Decoder)' initializer. Only \(Self.self) objects created using the 'init(key:, value:)' initializer can be reduced. (self.key: \(optionA.key), other.key: \(optionB.key))")
//            }
//            return type(of: matchingKey).reduceOption(optionA, with: optionB)
        }
        super.init(key: key)
    }
    
    
    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(key, forKey: .key)
        switch valueStorage {
        case .encoded(let data):
            try container.encode(data, forKey: .encodedValue)
        case .unencoded(value: _, let encodingFn):
            try container.encode(try encodingFn(), forKey: .encodedValue)
        }
    }
    
    
    public override var description: String {
        var desc = ""
        desc += "\(Self.self)(key: \(key)"
        switch valueStorage {
        case .encoded(let data):
            desc += ", value: \(data)"
        case .unencoded(let value, encodingFn: _):
            desc += ", value: \(value)"
        }
        desc += ")"
        return desc
    }
    
    
    public func readValue<Value: Codable>(as _: Value.Type) throws -> Value {
        switch valueStorage {
        case .unencoded(let value, encodingFn: _):
            if let typedValue = value as? Value {
                return typedValue
            } else {
                throw ApodiniDeploySupportError(message: "Unable to read value as '\(Value.self)'. (Actual type: '\(type(of: value))'.)")
            }
        case .encoded(let data):
            // The idea here is to "cache" the result of the decode operation,
            // by changing the value storage to an "unencoded" state (which just happens to contain the already-encoded value)
            let value = try JSONDecoder().decode(Value.self, from: data)
            self.valueStorage = ValueStorage.unencoded(value: value, encodingFn: { data })
            return value
        }
    }
    
    
    public func reduceOption(with other: ResolvedOption) -> ResolvedOption {
        reduceOptionsImp(other)
    }
    
    
    var untypedValue: Any? {
        switch valueStorage {
        case .encoded(_):
            return nil
        case .unencoded(let value, encodingFn: _):
            return value
        }
    }
}
