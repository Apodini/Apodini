//
//  Application+HTTP.swift
//  
//
//  Created by Tim Gymnich on 26.12.20.
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


import NIOSSL


/// The http najor version
public enum HTTPVersionMajor: Equatable, Hashable {
    case one
    case two
}


/// BindAddress
public enum BindAddress: Equatable {
    case hostname(_ hostname: String?, port: Int?)
    case unixDomainSocket(path: String)
}


extension Application {
    /// Used to keep track of http related configuration
    public var http: HTTP {
        .init(application: self)
    }

    /// Used to keep track of http related configuration
    public final class HTTP {
        final class Storage {
            var supportVersions: Set<HTTPVersionMajor>
            var tlsConfiguration: TLSConfiguration?
            var address: BindAddress?


            // swiftlint:disable discouraged_optional_collection
            init(
                supportVersions: Set<HTTPVersionMajor>? = nil,
                tlsConfiguration: TLSConfiguration? = nil,
                address: BindAddress? = nil
            ) {
                if let supportVersions = supportVersions {
                    self.supportVersions = supportVersions
                } else {
                    self.supportVersions = tlsConfiguration == nil ? [.one] : [.one, .two]
                }
                self.tlsConfiguration = tlsConfiguration
                self.address = address
            }
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

        /// Supported http major versions
        public var supportVersions: Set<HTTPVersionMajor> {
            get { storage.supportVersions }
            set { storage.supportVersions = newValue }
        }

        /// TLS configuration
        public var tlsConfiguration: TLSConfiguration? {
            get { storage.tlsConfiguration }
            set { storage.tlsConfiguration = newValue }
        }

        /// HTTP Server address
        public var address: BindAddress? {
            get { storage.address }
            set { storage.address = newValue }
        }

        init(application: Application) {
            self.application = application
        }

        func initialize() {
            self.application.storage[Key.self] = .init()
        }
    }
}
