//
//  ETag.swift
//  
//
//  Created by Paul Schmiedmayer on 6/16/21.
//

import Foundation


// MARK: ETag
/// An `Information` instance carrying an eTag that identifies a resource to enable caching
public struct ETag: Information {
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


// MARK: ETag Value
extension ETag {
    /// The content of an `ETag` `Information`
    public struct Value: RawRepresentable {
        let tag: String
        let isWeak: Bool
        
        
        public var rawValue: String {
            "\(isWeak ? "W/" : "")\"\(tag)\""
        }
        
        
        public init(tag: String, isWeak: Bool = false) {
            self.tag = tag
            self.isWeak = isWeak
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
            
            self = .init(tag: eTagValue, isWeak: isWeak)
        }
    }
}


// MARK: - AnyInformation + ETag
extension AnyInformation {
    /// An `Information` instance carrying an eTag that identifies a resource to enable caching
    public static func etag(_ tag: String, isWeak: Bool = false) -> AnyInformation {
        AnyInformation(ETag(ETag.Value(tag: tag, isWeak: isWeak)))
    }
}
