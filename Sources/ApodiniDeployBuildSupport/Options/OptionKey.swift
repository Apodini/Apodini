//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation


public class AnyOptionKey<OuterNS: OuterNamespace>: Codable, Hashable, Equatable, CustomStringConvertible {
    public let rawValue: String
    
    public init(key rawValue: String) {
        self.rawValue = "\(OuterNS.identifier):\(rawValue)"
    }
    
    public init(completeKey: String) {
        self.rawValue = completeKey
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


public class OptionKey<InnerNS: InnerNamespace, Value: OptionValue>: AnyOptionKey<InnerNS.OuterNS> {
    override public init(key rawValue: String) {
        super.init(key: "\(InnerNS.identifier).\(rawValue)")
    }
    
    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    
    override public init(completeKey: String) {
        super.init(completeKey: completeKey)
    }
    
    override public func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
    }
}


public final class OptionKeyWithDefaultValue<InnerNS: InnerNamespace, Value: OptionValue>: OptionKey<InnerNS, Value> {
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
