//
// Created by Lorena Schlesinger on 20.01.21.
//

import Foundation
@_implementationOnly import OpenAPIKit
@_implementationOnly import Yams

extension OpenAPI.Document {
    func output(_ format: OpenAPIOutputFormat) throws -> String? {
        let output: String?
        switch format {
        case .JSON:
            output = String(data: try JSONEncoder().encode(self), encoding: .utf8)
        case .YAML:
            output = try YAMLEncoder().encode(self)
        }
        return output
    }
}
