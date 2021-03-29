//
//  File.swift
//  
//
//  Created by Eldi Cano on 22.03.21.
//

import Foundation

struct DeltaStorageValue {
    let configuration: DeltaConfiguration
}

struct DeltaStorageKey: StorageKey {
    typealias Value = DeltaStorageValue
}

public class DeltaConfiguration: Configuration {

    var webServiceStructurePath: String?

    public init() {
        self.webServiceStructurePath = nil
    }

    public func configure(_ app: Application) {
        app.storage.set(DeltaStorageKey.self, to: DeltaStorageValue(configuration: self))
    }

    public func absolutePath(_ absolutePath: String) -> Self {
        self.webServiceStructurePath = absolutePath.hasSuffix("/") ? absolutePath : absolutePath + "/"
        return self
    }

}