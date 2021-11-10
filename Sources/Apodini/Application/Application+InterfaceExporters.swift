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
        
        func checkRegisteredExporter<T: InterfaceExporter>(exporterType: T.Type) -> Bool {
            self.interfaceExporters.contains { interfaceExporter in
                type(of: interfaceExporter) == exporterType
            }
        }
    }
    
    private enum InterfaceExporterKey: StorageKey {
        typealias Value = InterfaceExporterStorage
    }
    
    var interfaceExporters: [AnyInterfaceExporter] {
        storage[InterfaceExporterKey.self]?.interfaceExporters ?? []
    }
    
    private var interfaceExporterStorage: InterfaceExporterStorage {
        guard let exporterStorage = storage[InterfaceExporterKey.self] else {
            let exporterStorage = InterfaceExporterStorage()
            storage[InterfaceExporterKey.self] = exporterStorage
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
    
    /// Checks if an `InterfaceExporter` is already registered.
    /// - Parameter instance: The instance of the `InterfaceExporter` to register.
    /// - Returns: `true` if the `InterfaceExporter` type is already registered, `false` if the type isn't registered yet
    public func checkRegisteredExporter<T: InterfaceExporter>(exporterType: T.Type) -> Bool {
        interfaceExporterStorage.checkRegisteredExporter(exporterType: exporterType)
    }
}
