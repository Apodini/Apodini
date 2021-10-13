//
//  Request+ExporterRequestWithEventLoop.swift
//  
//
//  Created by Paul Schmiedmayer on 6/16/21.
//

import Apodini
import ApodiniExtension
import Vapor
import Foundation


extension Vapor.Request: RequestBasis {
    public var debugDescription: String {
        "Vapor.Request: \(self.description)"
    }
    
    public var information: Set<AnyInformation> {
        Set(headers.map { key, rawValue in
            AnyInformation(key: key, rawValue: rawValue)
        })
    }
}
