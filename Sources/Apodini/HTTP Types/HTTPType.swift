//
//  HTTPType.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//


public enum HTTPType: String, LosslessStringConvertible {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    
    
    public var description: String {
        return rawValue
    }
    
    
    public init?(_ description: String) {
        switch description.lowercased() {
        case HTTPType.get.rawValue.lowercased():
            self = .get
        case HTTPType.post.rawValue.lowercased():
            self = .post
        case HTTPType.put.rawValue.lowercased():
            self = .put
        case HTTPType.delete.rawValue.lowercased():
            self = .delete
        default:
            return nil
        }
    }
}
