//
// Created by Lorena Schlesinger on 20.01.21.
//

import Apodini
import ApodiniREST
import ApodiniUtils
import Foundation
import OpenAPIKit
@_implementationOnly import Yams

extension OpenAPI.Document {
    func output(configuration: OpenAPIExporterConfiguration) throws -> String? {
        let output: String?
        switch configuration.outputFormat {
        case .json:
            output = String(data: try JSONEncoder().encode(self), encoding: .utf8)
        case .yaml:
            output = try YAMLEncoder().encode(self)
        case .useParentEncoding:
            guard let RESTExporterConfiguration = dynamicCast(configuration.parentConfiguration, to: RESTExporterConfiguration.self) else {
                fatalError("No parent encoder specified!")
            }
            
            output = String(data: try RESTExporterConfiguration.encoder.encode(self), encoding: .utf8)
        }
        return output?.replacingOccurrences(of: "\\/", with: "/")
    }
}
