//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
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
