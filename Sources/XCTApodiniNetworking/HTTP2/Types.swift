//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import NIOHTTP1

struct HostAndPort: Equatable, Hashable {
    var host: String
    var port: Int
}

public struct TestHTTPRequest {
    class _Storage {
        var method: HTTPMethod
        var target: String
        var version: HTTPVersion
        var headers: [(String, String)]
        var body: [UInt8]?
        var trailers: [(String, String)]?

        init(method: HTTPMethod = .GET,
             target: String,
             version: HTTPVersion,
             headers: [(String, String)],
             body: [UInt8]?,
             trailers: [(String, String)]?) {
            self.method = method
            self.target = target
            self.version = version
            self.headers = headers
            self.body = body
            self.trailers = trailers
        }

    }

    private var _storage: _Storage

    public init(method: HTTPMethod = .GET,
                target: String,
                version: HTTPVersion = HTTPVersion(major: 1, minor: 1),
                headers: [(String, String)],
                body: [UInt8]?,
                trailers: [(String, String)]?) {
        self._storage = _Storage(method: method,
                                 target: target,
                                 version: version,
                                 headers: headers,
                                 body: body,
                                 trailers: trailers)
    }
}

extension TestHTTPRequest._Storage {
    func copy() -> TestHTTPRequest._Storage {
        return TestHTTPRequest._Storage(method: self.method,
                                            target: self.target,
                                            version: self.version,
                                            headers: self.headers,
                                            body: self.body,
                                            trailers: self.trailers)
    }
}

extension TestHTTPRequest {
    public var method: HTTPMethod {
        get {
            return self._storage.method
        }
        set {
            if !isKnownUniquelyReferenced(&self._storage) {
                self._storage = self._storage.copy()
            }
            self._storage.method = newValue
        }
    }

    public var target: String {
        get {
            return self._storage.target
        }
        set {
            if !isKnownUniquelyReferenced(&self._storage) {
                self._storage = self._storage.copy()
            }
            self._storage.target = newValue
        }
    }

    public var version: HTTPVersion {
        get {
            return self._storage.version
        }
        set {
            if !isKnownUniquelyReferenced(&self._storage) {
                self._storage = self._storage.copy()
            }
            self._storage.version = newValue
        }
    }

    public var headers: [(String, String)] {
        get {
            return self._storage.headers
        }
        set {
            if !isKnownUniquelyReferenced(&self._storage) {
                self._storage = self._storage.copy()
            }
            self._storage.headers = newValue
        }
    }

    public var body: [UInt8]? {
        get {
            return self._storage.body
        }
        set {
            if !isKnownUniquelyReferenced(&self._storage) {
                self._storage = self._storage.copy()
            }
            self._storage.body = newValue
        }
    }

    public var trailers: [(String, String)]? {
        get {
            return self._storage.trailers
        }
        set {
            if !isKnownUniquelyReferenced(&self._storage) {
                self._storage = self._storage.copy()
            }
            self._storage.trailers = newValue
        }
    }
}
