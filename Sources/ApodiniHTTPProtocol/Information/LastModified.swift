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
    private static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE',' dd MMM yyyy HH:mm:ss 'GMT'"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        return dateFormatter
    }()
    
    public static var header = "Last-Modified"
    
    public let value: Date
    
    public var rawValue: String {
        Self.dateFormatter.string(from: value)
    }
    
    
    public init?(rawValue: String) {
        guard let date = Self.dateFormatter.date(from: rawValue) else {
            return nil
        }
        
        self.init(date)
    }

    /// An `HTTPInformation` carrying information about the time a resource was last modified
    public init(_ value: Date) {
        self.value = value
    }
}
