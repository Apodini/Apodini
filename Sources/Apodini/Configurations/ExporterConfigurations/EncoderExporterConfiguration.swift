//
//  EncoderExporterConfiguration.swift
//  
//
//  Created by Philipp Zagar on 24.05.21.
//

import ApodiniUtils

open class EncoderExporterConfiguration: TopLevelExporterConfiguration {
    public let encoder: AnyEncoder
    public let decoder: AnyDecoder
    
    public init(encoder: AnyEncoder, decoder: AnyDecoder) {
        self.encoder = encoder
        self.decoder = decoder
        super.init()
    }
}
