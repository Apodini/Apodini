//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation


// MARK: ETag
/// An `Information` carrying information about the expiration date of resources
public struct Expires: Information {
    private static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US")
        dateFormatter.dateFormat = "EEE, dd LLL yyyy HH:mm:ss zzz"
        return dateFormatter
    }()
    
    public static var key: String {
        "Expires"
    }
    
    
    public private(set) var value: Date
    
    
    public var rawValue: String {
        Expires.dateFormatter.string(from: value)
    }
    
    
    public init?(rawValue: String) {
        guard let date = Expires.dateFormatter.date(from: rawValue) else {
            return nil
        }
        
        self.init(date)
    }
    
    public init(_ value: Date) {
        self.value = value
    }
}


// MARK: - AnyInformation + ETag
extension AnyInformation {
    /// An `Information` carrying information about the expiration date of resources
    public static func expires(_ eexpires: Expires.Value) -> AnyInformation {
        AnyInformation(Expires(eexpires))
    }
}
