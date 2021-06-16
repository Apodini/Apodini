//
//  ETag.swift
//  
//
//  Created by Paul Schmiedmayer on 6/16/21.
//

import Foundation


/// An `Information` instance carrying an eTag that identifies a resource to enable caching
public struct ETag: Information {
    /// The content of an `Authorization` `Information`
    public struct Value: RawRepresentable {
        let tag: String
        let isWeak: Bool
        
        
        public var rawValue: String {
            "\(isWeak ? "W/" : "")\"\(tag)\""
        }
        
        
        public init?(rawValue: String) {
            let isWeak = rawValue.hasPrefix("W/")
            var eTagValue = rawValue
            if isWeak {
                eTagValue.removeFirst(2)
            }
            
            guard eTagValue.hasPrefix("\"") && eTagValue.hasSuffix("\"") else {
                return nil
            }
            
            eTagValue.removeFirst()
            eTagValue.removeLast()
            
            self.tag = eTagValue
            self.isWeak = isWeak
        }
    }
    
    
    public static var key: String {
        "ETag"
    }
    
    
    public private(set) var value: Value
    
    
    public var rawValue: String {
        value.rawValue
    }
    
    
    public init?(rawValue: String) {
        guard let value = Value(rawValue: rawValue) else {
            return nil
        }
        
        self.init(value)
    }
    
    public init(_ value: Value) {
        self.value = value
    }
}
