//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//
//
// This code is based on the Vapor project: https://github.com/vapor/vapor
//
// SPDX-FileCopyrightText: 2020 Qutheory, LLC
//
// SPDX-License-Identifier: MIT
//           

extension Application {
    private final class InterfaceExporterStorage {
        var interfaceExporters: [AnyInterfaceExporter] = []
        
        func append(_ exporter: AnyInterfaceExporter) {
            self.interfaceExporters.append(exporter)
        }
    }
    
    private enum InterfaceExporerKey: StorageKey {
        typealias Value = InterfaceExporterStorage
    }
    
    var interfaceExporters: [AnyInterfaceExporter] {
        storage[InterfaceExporerKey.self]?.interfaceExporters ?? []
    }
    
    private var interfaceExporterStorage: InterfaceExporterStorage {
        guard let exporterStorage = storage[InterfaceExporerKey.self] else {
            let exporterStorage = InterfaceExporterStorage()
            storage[InterfaceExporerKey.self] = exporterStorage
            return exporterStorage
        }
        return exporterStorage
    }
    
    /// Registers an `InterfaceExporter` instance on the model builder.
    /// - Parameter instance: The instance of the `InterfaceExporter` to register.
    /// - Returns: `Self`
    @discardableResult
    public func registerExporter<T: InterfaceExporter>(exporter instance: T) -> Self {
        interfaceExporterStorage.append(AnyInterfaceExporter(instance))
        return self
    }
}
