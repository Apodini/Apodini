//
//  Authorization.swift
//  
//
//  Created by Paul Schmiedmayer on 6/16/21.
//

import Foundation


public struct Authorization {
    public let type: String
    public let credentials: String
    
    
    var value: String {
        "\(type) \(credentials)"
    }
    
    
    public static func basic(username: String, password: String) -> Authorization {
        let credentials = Data("\(username):\(password)".utf8).base64EncodedString()
        return Authorization(type: "Basic", credentials: credentials)
    }
    
    public static func bearer(_ token: String) -> Authorization {
        Authorization(type: "Bearer", credentials: token)
    }
    
    
    public init(type: String, credentials: String) {
        self.type = type
        self.credentials = credentials
    }
    
    init?(_ value: String) {
        let substrings = value.split(separator: " ", maxSplits: 1)
        guard substrings.count == 2 else {
            return nil
        }
        self = Authorization(type: String(substrings[0]), credentials: String(substrings[1]))
    }
}
