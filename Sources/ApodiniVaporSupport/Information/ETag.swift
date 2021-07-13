//
//  ETag.swift
//  
//
//  Created by Paul Schmiedmayer on 6/16/21.
//

import Apodini


// MARK: ETag
/// An `HTTPInformation` instance carrying an eTag that identifies a resource to enable caching
public struct ETag: HTTPInformation {
    public static let header = "ETag"
    
    public let value: Value
    
    
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

    /// An `HTTPInformation` instance carrying an eTag that identifies a resource to enable caching
    public init(_ tag: String, isWeak: Bool = false) {
        self.init(.init(tag: tag, isWeak: isWeak))
    }
}


// MARK: ETag Value
extension ETag {
    /// The content of an `ETag` `HTTPInformation`
    public struct Value {
        /// The tag string
        public let tag: String
        /// Holds the weakness of the ETag
        public let isWeak: Bool


        /// Returns the raw HTTP Header string value as transmitted over the wire
        public var rawValue: String {
            "\(isWeak ? "W/" : "")\"\(tag)\""
        }
        

        /// Instantiates a new `ETag.Value`.
        /// - Parameters:
        ///   - tag: The etag value.
        ///   - isWeak: Determines if its a weak etag.
        public init(tag: String, isWeak: Bool = false) {
            self.tag = tag
            self.isWeak = isWeak
        }

        /// Creates a new `ETag.Value` instance from the raw HTTP Header value.
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
