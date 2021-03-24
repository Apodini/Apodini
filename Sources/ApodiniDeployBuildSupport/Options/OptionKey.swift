//
//  OptionKey.swift
//
//
//  Created by Lukas Kollmer on 2021-02-06.
//

import Foundation


public class AnyOptionKey<OuterNS: OuterNamespace>: Codable, Hashable, Equatable, CustomStringConvertible {
    public let rawValue: String
    
    public init(key rawValue: String) {
        self.rawValue = "\(OuterNS.id):\(rawValue)"
    }
    
    public var description: String {
        "\(Self.self)('\(rawValue)')"
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }
    
    public static func == (lhs: AnyOptionKey, rhs: AnyOptionKey) -> Bool {
        lhs.rawValue == rhs.rawValue
    }
}


public class OptionKey<OuterNS, InnerNS: InnerNamespace, Value: OptionValue>: AnyOptionKey<OuterNS> where InnerNS.OuterNS == OuterNS {
    override public init(key rawValue: String) {
        super.init(key: "\(InnerNS.id).\(rawValue)")
    }
    
    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    
    override public func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
    }
}


public final class OptionKeyWithDefaultValue<OuterNS, InnerNS: InnerNamespace, Value: OptionValue>: OptionKey<OuterNS, InnerNS, Value>
where InnerNS.OuterNS == OuterNS {
    public let defaultValue: Value
    
    public init(key rawValue: String, defaultValue: Value) {
        self.defaultValue = defaultValue
        super.init(key: rawValue)
    }
    
    public required init(from decoder: Decoder) throws {
        fatalError("Cannot decode as type '\(Self.self)'. Use of of the base types instead.")
    }
    
    override public func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
    }
}