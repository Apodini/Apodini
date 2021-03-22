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

    let webServiceStructurePath: String

    public init(absolutePath: String) {
        self.webServiceStructurePath = absolutePath.hasSuffix("/") ? absolutePath : absolutePath + "/"
    }
    
    public func configure(_ app: Application) {
        app.storage.set(DeltaStorageKey.self, to: DeltaStorageValue(configuration: self))
    }
    
}
