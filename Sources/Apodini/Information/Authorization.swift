//
//  Authorization.swift
//  
//
//  Created by Paul Schmiedmayer on 6/16/21.
//

import Foundation


/// The content of an `.authorization` `Information`
public struct Authorization {
    /// The authorization type
    public let type: String
    /// The authorization credentials
    public let credentials: String
    
    
    var value: String {
        "\(type) \(credentials)"
    }
    
    
    /// Crerates a new `Authorization` instance that represents a basic authorization username and password combination
    /// - Parameters:
    ///   - username: The username that is encoded together with the password.
    ///   - password: The password that is encoded together with the username.
    /// - Returns: An `Authorization` instance encoding the `username` and `password` using the basic authorization mechanism
    /// - Warning: Please be aware  that the username and password is **not** encrrypted in a basic token, it is just base64 encoded!
    public static func basic(username: String, password: String) -> Authorization {
        let credentials = Data("\(username):\(password)".utf8).base64EncodedString()
        return Authorization(type: "Basic", credentials: credentials)
    }
    
    /// Crerates a new `Authorization` instance that represents a bearer authorization token
    /// - Parameter token: The token that is encoded in the bearer authorization.
    /// - Returns: An `Authorization` instance encoding the `token` using the bearer authorization mechanism
    public static func bearer(_ token: String) -> Authorization {
        Authorization(type: "Bearer", credentials: token)
    }
    
    
    /// Crerates a new `Authorization` instance
    /// - Parameters:
    ///   - type: The authorization type
    ///   - credentials: The authorization credentials
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
