//
//  File.swift
//  
//
//  Created by Tim Gymnich on 1.2.21.
//

import NIO

extension Application {
    /// Used to keep track of http related configuration
    public var exporters: Exporters {
        .init(application: self)
    }

    /// Used to wait for the application to stop
    public final class Exporters {
        final class Storage {
            var semanticModelBuilderBuilder: (SemanticModelBuilder) -> (SemanticModelBuilder) = { $0 }
            init() { }
        }

        struct Key: StorageKey {
            // swiftlint:disable nesting
            typealias Value = Storage
        }

        let application: Application

        var storage: Storage {
            if self.application.storage[Key.self] == nil {
                self.initialize()
            }
            // swiftlint:disable force_unwrapping
            return self.application.storage[Key.self]!
        }

        var semanticModelBuilderBuilder: (SemanticModelBuilder) -> (SemanticModelBuilder) {
            get { storage.semanticModelBuilderBuilder }
            set { storage.semanticModelBuilderBuilder = newValue }
        }

        init(application: Application) {
            self.application = application
        }

        func initialize() {
            self.application.storage[Key.self] = .init()
        }
    }
}
