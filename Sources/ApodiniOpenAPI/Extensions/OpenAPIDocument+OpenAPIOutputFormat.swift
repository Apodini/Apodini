//
// Created by Lorena Schlesinger on 20.01.21.
//

import Apodini
import ApodiniREST
import ApodiniUtils
import Foundation
import OpenAPIKit
@_implementationOnly import Yams

extension OpenAPIKit.OpenAPI.Document {
    func output(configuration: OpenAPI.ExporterConfiguration) throws -> String? {
        let output: String?
        switch configuration.outputFormat {
        case .json:
            output = String(data: try JSONEncoder().encode(self), encoding: .utf8)
        case .yaml:
            output = try YAMLEncoder().encode(self)
        case .useParentEncoding:
            output = String(data: try configuration.parentConfiguration.encoder.encode(self), encoding: .utf8)
        }
        
        return output?.replacingOccurrences(of: "\\/", with: "/")
    }
}
