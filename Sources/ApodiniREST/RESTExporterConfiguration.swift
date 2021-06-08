//
//  RESTExporterConfiguration.swift
//  
//
//  Created by Philipp Zagar on 21.05.21.
//

import Foundation
import Apodini

public struct RESTExporterConfiguration {
    public let encoder: AnyEncoder
    public let decoder: AnyDecoder
    
    public init(encoder: AnyEncoder = RESTInterfaceExporter.defaultEncoder,
                decoder: AnyDecoder = RESTInterfaceExporter.defaultDecoder) {
        self.encoder = encoder
        self.decoder = decoder
    }
}
