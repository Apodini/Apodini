//
//  HTTPType.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//


public struct HTTPType: LosslessStringConvertible {
    static let get: HTTPType = HTTPType("GET")
    static let post: HTTPType = HTTPType("POST")
    static let put: HTTPType = HTTPType("PUT")
    static let delete: HTTPType = HTTPType("DELETE")
    
    
    public let rawValue: String
    
    
    public var description: String {
        return rawValue
    }
    
    
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
}
