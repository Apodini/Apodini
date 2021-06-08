//
//  RESTExporterConfiguration.swift
//  
//
//  Created by Philipp Zagar on 21.05.21.
//

import Foundation
import Apodini

/// Configuration of the `RESTInterfaceExporter`
public struct RESTExporterConfiguration {
    /// The to be used `AnyEncoder` for encoding responses of the `RESTInterfaceExporter`
    public let encoder: AnyEncoder
    /// The to be used `AnyDecoder` for decoding requests to the `RESTInterfaceExporter`
    public let decoder: AnyDecoder
    
    /**
     Initializes the `RESTExporterConfiguration` of the `RESTInterfaceExporter`
     - Parameters:
         - encoder: The to be used `AnyEncoder`, defaults to a `JSONEncoder`
         - decoder: The to be used `AnyDecoder`, defaults to a `JSONDecoder`
     */
    public init(encoder: AnyEncoder = RESTInterfaceExporter.defaultEncoder,
                decoder: AnyDecoder = RESTInterfaceExporter.defaultDecoder) {
        self.encoder = encoder
        self.decoder = decoder
    }
}
