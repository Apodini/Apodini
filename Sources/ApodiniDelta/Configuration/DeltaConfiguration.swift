//
//  File.swift
//  
//
//  Created by Eldi Cano on 22.03.21.
//

import Foundation
import ApodiniUtils

/// Represents cases how the web service structure should be trated
public enum DeltaStrategy {
    /// Creates and persists the web service structure
    case create
    /// Compares the generated structure with the previously persisted one
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
    var webServiceStructurePath: String?
    var strategy: DeltaStrategy = .create

    public init() {
        self.webServiceStructurePath = nil
        
        #if Xcode
        runShellCommand(.killPort(8080))
        #endif
    }

    public func configure(_ app: Application) {
        app.storage.set(DeltaStorageKey.self, to: DeltaStorageValue(configuration: self))
    }

    /// Registers the absolute path for persisting the web service structure
    public func absolutePath(_ absolutePath: String) -> Self {
        self.webServiceStructurePath = absolutePath.hasSuffix("/") ? absolutePath : absolutePath + "/"
        return self
    }

    /// Specifies strategy how the web service structure should be trated.
    /// Default strategy is `create`
    public func strategy(_ strategy: DeltaStrategy) -> Self {
        self.strategy = strategy
        return self
    }
}
