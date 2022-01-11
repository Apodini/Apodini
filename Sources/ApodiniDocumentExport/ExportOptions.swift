import Foundation
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
