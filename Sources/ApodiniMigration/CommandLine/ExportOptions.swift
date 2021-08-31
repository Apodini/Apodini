//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import ApodiniMigrator
import ArgumentParser

/// An object that defines export options of `ApodiniMigrator` items
public struct ExportOptions: ParsableArguments {
    @Option(help: "A path to a local directory used to export an item")
    var directory: String?
    
    @Option(help: "An endpoint path of the web service used to expose an item")
    var endpoint: String?
    
    @Option(help: "Format of the item to be exported / exposed, either `json` or `yaml`. Defaults to `json`")
    var format: FileFormat = .json
    
    init(directory: String? = nil, endpoint: String? = nil, format: FileFormat) {
        self.directory = directory
        self.endpoint = endpoint
        self.format = format
    }
    
    /// Creates an instance of this parsable type using the definitions given by each property’s wrapper.
    public init() {}
    
    /// Validates whether at least one of the properties `directory` or `endpoint`
    /// are not `nil`
    public func validate() throws {
        guard directory != nil || endpoint != nil else {
            throw ValidationError(
                "`migrator` subcommand requires at least one of the paths `directory` or `endpoint` to export its items"
            )
        }
    }
    
    
    /// A convenient static function for initializing an `ExportOptions` instance
    /// - Parameters:
    ///   - path: A path to a local directory used to export an item
    ///   - format: Format of the item to be exported, either `json` or `yaml`. Defaults to `.json`
    /// - Returns: a `DocumentConfiguration` instance
    public static func directory(_ path: String, format: FileFormat = .json) -> ExportOptions {
        .init(directory: path, format: format)
    }
    
    /// A convenient static function for initializing an `ExportOptions` instance
    /// - Parameters:
    ///   - path: An endpoint path of the web service used to expose an item
    ///   - format: Format of the item to be exposed, either `json` or `yaml`. Defaults to `.json`
    /// - Returns: a `DocumentConfiguration` instance
    public static func endpoint(_ path: String, format: FileFormat = .json) -> ExportOptions {
        .init(endpoint: path, format: format)
    }
    
    /// A convenient static function for initializing an `ExportOptions` instance
    /// - Parameters:
    ///   - directory: A path to a local directory used to export an item
    ///   - endpoint: An endpoint path of the web service used to expose an item
    ///   - format: Format of the item to be exposed, either `json` or `yaml`. Defaults to `.json`
    public static func paths(directory: String, endpoint: String, format: FileFormat = .json) -> ExportOptions {
        .init(directory: directory, endpoint: endpoint, format: format)
    }
}
