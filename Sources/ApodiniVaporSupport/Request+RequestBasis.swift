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

    public var information: InformationSet {
        InformationSet(headers.map { key, rawValue in
            AnyHTTPInformation(key: key, rawValue: rawValue)
        })
    }
}
