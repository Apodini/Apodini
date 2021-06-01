//
//  File.swift
//
//
//  Created by Eldi Cano on 22.03.21.
//

import Foundation
import Apodini

/// Represents cases how the document structure should be trated
public enum DeltaStrategy {
    /// Creates and persists the document
    case create
    /// Compares the generated document with the previously persisted one
    case compare
}

struct DeltaStorageValue {
    let configuration: DeltaConfiguration
}

struct DeltaStorageKey: StorageKey {
    typealias Value = DeltaStorageValue
}

/// Configuration used for ApodiniDelta
public class DeltaConfiguration: Configuration {
    var absolutePath: String?
    var strategy: DeltaStrategy

    public init() {
        self.absolutePath = nil
        self.strategy = .create
        
        #if Xcode
        runShellCommand(.killPort(8080))
        #endif
    }

    public func configure(_ app: Application) {
        app.storage.set(DeltaStorageKey.self, to: DeltaStorageValue(configuration: self))
    }

    /// Registers the absolute path for persisting the document
    public func absolutePath(_ absolutePath: String) -> Self {
        self.absolutePath = absolutePath.hasSuffix("/") ? absolutePath : absolutePath + "/"
        return self
    }

    /// Specifies strategy how the document should be trated.
    /// Default strategy is `create`
    public func strategy(_ strategy: DeltaStrategy) -> Self {
        self.strategy = strategy
        return self
    }
}
