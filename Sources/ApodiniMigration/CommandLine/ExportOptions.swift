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

/// A typealias for `OutputFormat`
public typealias FileFormat = OutputFormat

extension OutputFormat: ExpressibleByArgument {}

/// A protocol that defines export options for `ApodiniMigrator` items
public protocol ExportOptions: ParsableArguments {
    /// Optional directory path to export an item
    var directory: String? { get set }
    /// Optional endpoint path to expose an item
    var endpoint: String? { get set }
    /// Format of the item to be exported / exposed, either `json` or `yaml`
    var format: FileFormat { get set }
}

extension ExportOptions {
    init(directory: String?, endpoint: String?, format: FileFormat) {
        self.init()
        self.directory = directory
        if let endpoint = endpoint {
            self.endpoint = endpoint.hasPrefix("/") ? endpoint : "/\(endpoint)"
        }
        self.format = format
    }
}

public extension ExportOptions {
    /// If initialized through command line validates whether at least one of the paths `directory` or `endpoint` are not `nil`
    func validate() throws {
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
    static func directory(_ path: String, format: FileFormat = .json) -> Self {
        .init(directory: path, endpoint: nil, format: format)
    }
    
    /// A convenient static function for initializing an `ExportOptions` instance
    /// - Parameters:
    ///   - path: An endpoint path of the web service used to expose an item
    ///   - format: Format of the item to be exposed, either `json` or `yaml`. Defaults to `.json`
    static func endpoint(_ path: String, format: FileFormat = .json) -> Self {
        .init(directory: nil, endpoint: path, format: format)
    }
    
    /// A convenient static function for initializing an `ExportOptions` instance
    /// - Parameters:
    ///   - directory: A path to a local directory used to export an item
    ///   - endpoint: An endpoint path of the web service used to expose an item
    ///   - format: Format of the item to be exposed, either `json` or `yaml`. Defaults to `.json`
    static func paths(directory: String, endpoint: String, format: FileFormat = .json) -> Self {
        .init(directory: directory, endpoint: endpoint, format: format)
    }
}

// swiftlint:disable line_length
/// An object that defines export options of the API Document
public struct DocumentExportOptions: ExportOptions {
    /// A path to a local directory used to export API document
    @Option(name: .customLong("doc-directory"), help: "A path to a local directory used to export API document")
    public var directory: String?
    /// An endpoint path of the web service used to expose API document
    @Option(name: .customLong("doc-endpoint"), help: "An endpoint path of the web service used to expose API document")
    public var endpoint: String?
    /// Format of the API document to be exported / exposed, either `json` or `yaml`. Defaults to `json`
    @Option(name: .customLong("doc-format"), help: "Format of the API document to be exported / exposed, either `json` or `yaml`. Defaults to `json`")
    public var format: FileFormat = .json
    
    /// Creates an instance of this parsable type using the definitions given by each property’s wrapper.
    public init() {}
}

/// An object that defines export options of the API Document
public struct MigrationGuideExportOptions: ExportOptions {
    /// A path to a local directory used to export the migration guide
    @Option(name: .customLong("guide-directory"), help: "A path to a local directory used to export the migration guide")
    public var directory: String?
    /// An endpoint path of the web service used to expose the migration guide
    @Option(name: .customLong("guide-endpoint"), help: "An endpoint path of the web service used to expose the migration guide")
    public var endpoint: String?
    /// Format of the migration guide to be exported / exposed, either `json` or `yaml`. Defaults to `json`
    @Option(name: .customLong("guide-format"), help: "Format of the migration guide to be exported / exposed, either `json` or `yaml`. Defaults to `json`")
    public var format: FileFormat = .json
    
    /// Creates an instance of this parsable type using the definitions given by each property’s wrapper.
    public init() {}
}
// swiftlint:enable line_length
