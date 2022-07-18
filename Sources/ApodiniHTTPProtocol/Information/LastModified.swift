//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Apodini
import Foundation

// MARK: Last-Modified
/// An `HTTPInformation` instance carrying a Last -Modified data that indicates when a resource was last modified.
public struct LastModified: HTTPInformation {
    public static var header: String {
        print("Hi")
        return "Last-Modified"
    }
    
    public let value: LastModifiedValue
    
    public var rawValue: String {
        value.rawValue
    }
    
    public init?(rawValue: String) {
        guard let value = LastModifiedValue(rawValue: rawValue) else {
            return nil
        }
        
        self.init(value)
    }
    
    public init(_ date: Date) {
        let value = LastModifiedValue(date: date)
        
        self.init(value)
    }
    
    public init(_ value: LastModifiedValue) {
        self.value = value
    }
}


// MARK: LastModified Value
extension LastModified {
    /// The content of a `LastModified` `HTTPInformation`
    public struct LastModifiedValue {
        private static let dateFormatter: DateFormatter = {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "EEE',' dd MMM yyyy HH:mm:ss 'GMT'"
            dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            return dateFormatter
        }()
        
        /// The date representing the `LastModifiedValue`
        public let date: Date

        /// Returns the raw HTTP Header string value as transmitted over the wire
        public var rawValue: String {
            Self.dateFormatter.string(from: date)
        }
        

        /// Instantiates a new `LastModifiedValue`.
        public init(date: Date) {
            self.date = date
        }

        /// Creates a new `LastModifiedValue` instance from the raw HTTP Header value.
        public init?(rawValue: String) {
            guard let date = Self.dateFormatter.date(from: rawValue) else {
                return nil
            }
            
            self.date = date
        }
    }
}
