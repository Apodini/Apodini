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

/// A typealias for ``OutputFormat``
public typealias FileFormat = OutputFormat

extension OutputFormat: ExpressibleByArgument {}

// MARK: - ExportOptions
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
    init(directory: String? = nil, endpoint: String? = nil, format: FileFormat) {
        self.init()
        self.directory = directory
        self.endpoint = endpoint
        self.format = format
    }
}

public extension ExportOptions {
    /// A convenient static function for initializing an ``ExportOptions`` instance
    /// - Parameters:
    ///   - path: A path to a local directory used to export an item
    ///   - format: Format of the item to be exported, either `json` or `yaml`. Defaults to `.json`
    static func directory(_ path: String, format: FileFormat = .json) -> Self {
        .init(directory: path, format: format)
    }
    
    /// A convenient static function for initializing an ``ExportOptions`` instance
    /// - Parameters:
    ///   - path: An endpoint path of the web service used to expose an item
    ///   - format: Format of the item to be exposed, either `json` or `yaml`. Defaults to `.json`
    static func endpoint(_ path: String, format: FileFormat = .json) -> Self {
        .init(endpoint: path, format: format)
    }
    
    /// A convenient static function for initializing an ``ExportOptions`` instance
    /// - Parameters:
    ///   - directory: A path to a local directory used to export an item
    ///   - endpoint: An endpoint path of the web service used to expose an item
    ///   - format: Format of the item to be exposed, either `json` or `yaml`. Defaults to `.json`
    static func paths(directory: String, endpoint: String, format: FileFormat = .json) -> Self {
        .init(directory: directory, endpoint: endpoint, format: format)
    }
}

// MARK: - DocumentExportOptions
/// An object that defines export options of the API Document
public struct DocumentExportOptions: ExportOptions {
    /// A path to a local directory used to export API document
    @Option(name: .customLong("doc-directory"), help: "A path to a local directory used to export API document")
    public var docDirectory: String?
    /// An endpoint path of the web service used to expose API document
    @Option(name: .customLong("doc-endpoint"), help: "An endpoint path of the web service used to expose API document")
    public var docEndpoint: String?
    /// Format of the API document to be exported / exposed, either `json` or `yaml`. Defaults to `json`
    @Option(name: .customLong("doc-format"), help: "Format of the API document to be exported / exposed, either `json` or `yaml`")
    public var docFormat: FileFormat = .json
    
    
    public var directory: String? {
        get { docDirectory }
        set { docDirectory = newValue }
    }
    public var endpoint: String? {
        get { docEndpoint }
        set { docEndpoint = newValue }
    }
    public var format: FileFormat {
        get { docFormat }
        set { docFormat = newValue }
    }
    
    
    /// Creates an instance of this parsable type using the definitions given by each property’s wrapper.
    public init() {}
}

// MARK: - MigrationGuideExportOptions
/// An object that defines export options of the API Document
public struct MigrationGuideExportOptions: ExportOptions {
    /// A path to a local directory used to export the migration guide
    @Option(name: .customLong("guide-directory"), help: "A path to a local directory used to export the migration guide")
    public var guideDirectory: String?
    /// An endpoint path of the web service used to expose the migration guide
    @Option(name: .customLong("guide-endpoint"), help: "An endpoint path of the web service used to expose the migration guide")
    public var guideEndpoint: String?
    /// Format of the migration guide to be exported / exposed, either `json` or `yaml`. Defaults to `json`
    @Option(name: .customLong("guide-format"), help: "Format of the migration guide to be exported / exposed, either `json` or `yaml`")
    public var guideFormat: FileFormat = .json
    
    
    public var directory: String? {
        get { guideDirectory }
        set { guideDirectory = newValue }
    }
    public var endpoint: String? {
        get { guideEndpoint }
        set { guideEndpoint = newValue }
    }
    public var format: FileFormat {
        get { guideFormat }
        set { guideFormat = newValue }
    }
    
    
    /// Creates an instance of this parsable type using the definitions given by each property’s wrapper.
    public init() {}
}
