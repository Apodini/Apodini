//
//  Request+ExporterRequestWithEventLoop.swift
//  
//
//  Created by Paul Schmiedmayer on 6/16/21.
//

import Apodini
import Vapor
import Foundation


extension Vapor.Request: ExporterRequestWithEventLoop {
    public var information: Set<AnyInformation> {
        Set(headers.map { key, rawValue in
            AnyInformation(key: key, rawValue: rawValue)
        })
    }
}
