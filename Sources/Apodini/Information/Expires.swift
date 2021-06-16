//
//  Expires.swift
//  
//
//  Created by Paul Schmiedmayer on 6/16/21.
//

import Foundation


/// An `Information` carrying information about the expiration date of resources
public struct Expires: Information {
    private static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
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
