//
//  Authorization.swift
//  
//
//  Created by Paul Schmiedmayer on 6/16/21.
//

import Foundation
import Apodini


// MARK: Authorization
/// An `HTTPInformation` carrying authorization information.
public struct Authorization: HTTPInformation {
    public static let header = "Authorization"

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

    /// An `HTTPInformation` carrying authorization information
    /// - Parameter authorization: The content of an `Authorization` `Information`
    public init(_ value: Value) {
        self.value = value
    }
}


// MARK: Authorization Value
extension Authorization {
    /// The content of an `Authorization` `HTTPInformation`
    public struct Value {
        /// The authorization type
        public let type: String
        /// The authorization credentials
        public let credentials: String
        
        
        /// Returns the raw HTTP Header string value as transmitted over the wire
        public var rawValue: String {
            "\(type) \(credentials)"
        }
        
        /// `username` and `password` using the basic authorization mechanism if the `Authorization.Value` is based on basic authorization
        public var basic: (username: String, password: String)? {
            guard type == "Basic",
                  let base64data = Data(base64Encoded: credentials),
                  let usernameAndPassword = String(data: base64data, encoding: .utf8) else {
                return nil
            }
            
            let splitString = usernameAndPassword.split(separator: ":", maxSplits: 1)
            
            guard splitString.count == 2 else {
                return nil
            }
            
            return (String(splitString[0]), String(splitString[1]))
        }
        
        /// The bearer token the `Authorization.Value` is based on bearer authorization
        public var bearerToken: String? {
            guard type == "Bearer" else {
                return nil
            }
            
            return credentials
        }
        
        
        /// Creates a new `Authorization.Value` instance that represents a basic authorization username and password combination
        /// - Parameters:
        ///   - username: The username that is encoded together with the password.
        ///   - password: The password that is encoded together with the username.
        /// - Returns: An `Authorization` instance encoding the `username` and `password` using the basic authorization mechanism
        /// - Warning: Please be aware  that the username and password is **not** encrypted in a basic token, it is just base64 encoded!
        public static func basic(username: String, password: String) -> Self {
            let credentials = Data("\(username):\(password)".utf8).base64EncodedString()
            return Self(type: "Basic", credentials: credentials)
        }
        
        /// Creates a new `Authorization.Value` instance that represents a bearer authorization token
        /// - Parameter token: The token that is encoded in the bearer authorization.
        /// - Returns: An `Authorization` instance encoding the `token` using the bearer authorization mechanism
        public static func bearer(_ token: String) -> Self {
            Self(type: "Bearer", credentials: token)
        }
        
        
        /// Creates a new `Authorization.Value` instance
        /// - Parameters:
        ///   - type: The authorization type
        ///   - credentials: The authorization credentials
        public init(type: String, credentials: String) {
            self.type = type
            self.credentials = credentials
        }

        /// Creates a new `Authorization.Value` instance from the raw HTTP Header value.
        public init?(rawValue: String) {
            let substrings = rawValue.split(separator: " ", maxSplits: 1)
            guard substrings.count == 2 else {
                return nil
            }
            self = Self(type: String(substrings[0]), credentials: String(substrings[1]))
        }
    }
}
