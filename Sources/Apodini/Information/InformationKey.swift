//
//  InformationKey.swift
//  
//
//  Created by Paul Schmiedmayer on 6/16/21.
//


/// A key uniquely describing an `Information` case.
public enum InformationKey: RawRepresentable {
    /// An `Information` instance carrying `Authorization` information
    case authorization
    /// An `Information` instance carrying information about cookies
    case cookies
    /// An `Information` instance carrying information that redirects a client to a new location
    case redirectTo
    /// An `Information` instance carrying information that indicates when a resource expires for caching information
    case expires
    /// An `Information` instance carrying an eTag that identifies a resource to enable caching
    case eTag
    /// An `Information` instance carrying that is unknown to Apodini
    case unknown(String)
    
    
    public var rawValue: String {
        switch self {
        case .authorization:
            return "Authorization"
        case .cookies:
            return "Cookie"
        case .redirectTo:
            return "Location"
        case .expires:
            return "Expires"
        case .eTag:
            return "ETag"
        case let .unknown(rawValue):
            return rawValue
        }
    }
    
    
    public init(rawValue: String) {
        switch rawValue {
        case InformationKey.authorization.rawValue:
            self = .authorization
        case InformationKey.cookies.rawValue:
            self = .cookies
        case InformationKey.redirectTo.rawValue:
            self = .redirectTo
        case InformationKey.expires.rawValue:
            self = .expires
        case InformationKey.eTag.rawValue:
            self = .eTag
        default:
            self = .unknown(rawValue)
        }
    }
}


extension InformationKey: Hashable {
    public static func == (lhs: InformationKey, rhs: InformationKey) -> Bool {
        lhs.rawValue == rhs.rawValue
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }
}
