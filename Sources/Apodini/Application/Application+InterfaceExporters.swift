//
//  Application+InterfaceExporters.swift
//  
//
//  Created by Philipp Zagar on 11.06.21.
//
//
// This code is based on the Vapor project: https://github.com/vapor/vapor
//
// The MIT License (MIT)
//
// Copyright (c) 2020 Qutheory, LLC
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

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
    
    /// Registers an `StaticInterfaceExporter` instance on the model builder.
    /// - Parameter instance: The instance of the `StaticInterfaceExporter` to register.
    /// - Returns: `Self`
    @discardableResult
    public func registerExporter<T: StaticInterfaceExporter>(staticExporter instance: T) -> Self {
        interfaceExporterStorage.append(AnyInterfaceExporter(instance))
        return self
    }
}
