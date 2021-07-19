//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation
import Apodini


// MARK: ETag
/// An `HTTPInformation` carrying information about the expiration date of resources
public struct Expires: HTTPInformation {
    fileprivate static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US")
        dateFormatter.dateFormat = "EEE, dd LLL yyyy HH:mm:ss zzz"
        return dateFormatter
    }()

    public static let header = "Expires"
    
    
    public let value: Date
    
    
    public var rawValue: String {
        Expires.dateFormatter.string(from: value)
    }
    
    
    public init?(rawValue: String) {
        guard let date = Expires.dateFormatter.date(from: rawValue) else {
            return nil
        }
        
        self.init(date)
    }

    /// An `HTTPInformation` carrying information about the expiration date of resources
    public init(_ value: Date) {
        self.value = value
    }
}
