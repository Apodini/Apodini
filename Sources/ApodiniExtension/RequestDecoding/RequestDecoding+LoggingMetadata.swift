//
//  RequestDecoding+LoggingMetadata.swift
//
//  Created by Philipp Zagar on 01.08.21.
//

import Apodini
import Logging

extension DecodingRequest {
    public var loggingMetadata: Logger.Metadata {
        [
            "parameters": .dictionary(self.parameterLoggingMetadata)
        ]
        .merging(self.basis.loggingMetadata) { _, new in new }
        //.merging(self.input.loggingMetadata) { _, new in new }
    }
}
