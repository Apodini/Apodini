//
//  File.swift
//  
//
//  Created by Lorena Schlesinger on 29.11.20.
//

import Foundation

struct OpenAPIComponentBuilderError: Error {
    let message: String

    init(_ message: String) {
        self.message = message
    }
}

struct OpenAPISchemaError: Error {
}
