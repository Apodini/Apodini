//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini

/// An `HTTPInformation` instance carrying information about cookies
public struct Cookies: HTTPInformation {
    public static let header = "Cookie"
    
    public let value: [String: String]
    
    
    public var rawValue: String {
        value.map { "\($0.0)=\($0.1)" }.joined(separator: "; ")
    }
    
    
    public init?(rawValue: String) {
        let keyValuePairs = rawValue.components(separatedBy: "; ")
        var cookies: [String: String] = Dictionary(minimumCapacity: keyValuePairs.count)
        
        for keyValuePair in keyValuePairs {
            if keyValuePair.count < 3 {
                continue
            }
            
            let substrings = keyValuePair.split(separator: "=", maxSplits: 1)
            guard substrings.count == 2 else {
                continue
            }
            cookies[String(substrings[0])] = String(substrings[1])
        }
        
        self.init(cookies)
    }

    /// An `HTTPInformation` instance carrying information about cookies
    public init(_ value: [String: String]) {
        self.value = value
    }

    public func merge(with information: Cookies) -> Cookies {
        Cookies(value.merging(information.value, uniquingKeysWith: { _, new in new }))
    }
}
