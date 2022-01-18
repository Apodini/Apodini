#  Document Export

Create a document to store knowledge on your Apodini web service and export it in a local directory or expose a new endpoint.

<!--
                  
This source file is part of the Apodini open source project

SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>

SPDX-License-Identifier: MIT
             
-->

## Overview

`ApodiniDocumentExport` supports the creation and export of documents to store information on the endpoints and structure of your Apodini web service.

> Tip: See `ApodiniSustainability` and `ApodiniMigration` as references to start with your implementation of this use case.

### Dependency

Add `ApodiniDocumentExport` product to your target dependencies in `package.swift`: 
```swift
.product(name: "ApodiniDocumentExport", package: "Apodini")
```

### Documents

The structure of your document is unique to your use case. You may use the `Value` protocol to require conformance to `Codable` and `Hashable`.

```swift
/// A document that describes an Apodini Web Service
public struct Document: Value {
    <#code#>
}
```

### Export Options

`ExportOptions` provides a protocol to specify the document's `format` and optional `directory` and `endpoint` properties. `ApodiniDocumentExport` supports `.json` and `.yaml` format. You may use `ArgumentParser` to enable command line arguments. See <doc:CommandLineArguments> for more information.

```swift
struct DocumentExportOptions: ExportOptions {
    /// A path to a local directory used to export document
    @Option(name: .customLong("directory"), help: "A path to a local directory to export document")
    public var directory: String?
    /// An endpoint path of the web service used to expose document
    @Option(name: .customLong("endpoint"), help: "A path to an endpoint of the web service to expose document")
    public var endpoint: String?
    /// Format of the document export
    ///
    /// Supports `json` or `yaml` format.
    /// - Note: Defaults to `json`
    @Option(name: .customLong("format"), help: "Format of the document, either `json` or `yaml`")
    public var format: FileFormat = .json
    
    /// Creates an instance of this parsable type using the definitions given by each property’s wrapper.
    public init() {}
}
```

### Interface Exporter

Apodini enables you to build a new ``InterfaceExporter`` to collect information on your web service and initialize a `document` instance. This implementation of ``InterfaceExporter/finishedExporting(_:)-9eep3`` shows how to use `ApodiniDocumentExport` to write a document to a local directory or expose a new endpoint. See <doc:BuildingExporters> for more information. 

```swift
final class DocumentInterfaceExporter: InterfaceExporter {
    
    private let app: Application
    private let configuration: DocumentConfiguration
    private let logger = Logger(label: <#String#>)
    
    init(_ app: Application, configuration: DocumentConfiguration) {
        self.app = app
        self.configuration = configuration
    }
    
    func export<H>(_ endpoint: Apodini.Endpoint<H>) -> () where H : Handler {
        <#code#>
    }
    
    func export<H>(blob endpoint: Apodini.Endpoint<H>) -> () where H : Handler, H.Response.Content == Blob {
        <#code#>
    }
    
    func finishedExporting(_ webService: WebServiceModel) {
        
        app.storage.set(DocumentStorageKey.self, to: document)
        
        guard let options = configuration.exportOptions else {
            return logger.notice("No configuration provided to handle document")
        }
            
        if let directory = options.directory {
            do {
                let filePath = try document.write(at: directory, outputFormat: options.format)
                logger.info("Document exported at \(filePath) in \(options.format.rawValue)")
            } catch {
                logger.error("Document export at \(directory) failed with error: \(error)")
            }
        }
        
        if let endpoint = options.endpoint {
            app.httpServer.registerRoute(.GET, endpoint.httpPathComponents) { _ -> String in
                options.format.string(of: document)
            }
            logger.info("Document served at \(endpoint) in \(options.format.rawValue) format")
        }
    }
}
```

### Document Configuration

Create a ``Apodini/Configuration`` and use ``Application/registerExporter(exporter:)`` to register your ``InterfaceExporter`` implementation with the ``Application``.

```swift
public class DocumentConfiguration: Configuration {
    
    let exportOptions: DocumentExportOptions?
    
    /// Initializer for a ``DocumentConfiguration`` instance
    /// - Parameter exportOptions: Export options of the document
    public init(_ exportOptions: DocumentExportOptions? = nil) {
        self.exportOptions = exportOptions
    }
    
    /// Configures `app` by registering the ``InterfaceExporter`` that handles document export
    /// - Parameter app: Application instance to register the configuration in Apodini
    public func configure(_ app: Application) {
        app.registerExporter(exporter: DocumentInterfaceExporter(app, configuration: self))
    }
}

public extension WebService {
    /// A typealias for ``DocumentConfiguration``
    typealias Document = DocumentConfiguration
}
```

This example shows how to use the implementation in your Apodini web service `configuration`. See <doc:ExporterConfiguration> for more information.

```swift
struct HelloWorld: WebService {
    
    @OptionGroup
    var options: DocumentExportOptions
    
    var configuration: Configuration {
        Document(options)
    }

    var content: some Component {
        Greeter()
    }
}
```

## Topics

### Apodini

- ``Application``
- ``Configuration``
- ``Endpoint``
- ``InterfaceExporter``
- ``WebServiceModel``
