//
//  RedirectTo.swift
//  
//
//  Created by Paul Schmiedmayer on 6/16/21.
//

import Foundation


// MARK: RedirectTo
/// An `Information` instance carrying information that redirects a client to a new location
public struct RedirectTo: Information {
    public static var key: String {
        "Location"
    }
    
    
    public private(set) var value: URL
    
    
    public var rawValue: String {
        value.absoluteString
    }
    
    
    public init?(rawValue: String) {
        guard let url = URL(string: rawValue) else {
            return nil
        }
        
        self.init(url)
    }
    
    public init(_ value: URL) {
        self.value = value
    }
}


// MARK: - AnyInformation + RedirectTo
extension AnyInformation {
    /// An `Information` instance carrying information that redirects a client to a new location
    public static func redirectTo(_ redirectTo: RedirectTo.Value) -> AnyInformation {
        AnyInformation(RedirectTo(redirectTo))
    }
}
