//
//  File.swift
//  
//
//  Created by Simon Bohnen on 4/8/22.
//

import Foundation
import Apodini
import ApodiniREST
import ApodiniHTTP

struct APIAuditor: RESTDependentStaticConfiguration, HTTPDependentStaticConfiguration {
    public func configure(_ app: Apodini.Application, parentConfiguration: REST.ExporterConfiguration) {
        
    }
    
    public func configure(_ app: Apodini.Application, parentConfiguration: HTTP.ExporterConfiguration) {
        
    }
}
