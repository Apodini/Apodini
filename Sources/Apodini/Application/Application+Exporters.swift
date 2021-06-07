//
//  Application+Exporters.swift
//  
//
//  Created by Tim Gymnich on 1.2.21.
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

        /// The `SemanticModelBuilder` to register services upon
        public var semanticModelBuilderBuilder: (SemanticModelBuilder) -> (SemanticModelBuilder) {
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
