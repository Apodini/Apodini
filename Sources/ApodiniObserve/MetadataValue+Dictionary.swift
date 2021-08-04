//
//  MetadataValue+Dictionary.swift
//
//  Created by Philipp Zagar on 01.08.21.
//

import Logging

/// Extension that allows easy access to the `.dictionary`case of the `Logger.Metadata`
public extension Logger.MetadataValue {
    /// A computed property that allows easy access to the `.dictionary`case of the ``Logger.Metadata``
    var metadataDictionary: Logger.Metadata {
        switch self {
        case .dictionary(let dictionary):
            return dictionary
        default: return [:]
        }
    }
}
