//
//  RedirectTo.swift
//  
//
//  Created by Paul Schmiedmayer on 6/16/21.
//

import Foundation
import Apodini

// MARK: RedirectTo
/// An `HTTPInformation` instance carrying information that redirects a client to a new location
public struct RedirectTo: HTTPInformation {
    public static var header = "Location"

    public let value: URL

    public var rawValue: String {
        value.absoluteString
    }
    
    public init?(rawValue: String) {
        guard let url = URL(string: rawValue) else {
            return nil
        }
        
        self.init(url)
    }

    /// An `HTTPInformation` instance carrying information that redirects a client to a new location
    public init(_ value: URL) {
        self.value = value
    }
}
