//
// Created by Lorena Schlesinger on 20.01.21.
//

import Foundation
import OpenAPIKit
@_implementationOnly import Yams

extension OpenAPI.Document {
    func output(_ format: OpenAPIOutputFormat) throws -> String? {
        let output: String?
        switch format {
        case .json:
            output = String(data: try JSONEncoder().encode(self), encoding: .utf8)
        case .yaml:
            output = try YAMLEncoder().encode(self)
        }
        return output?.replacingOccurrences(of: "\\/", with: "/")
    }
}
