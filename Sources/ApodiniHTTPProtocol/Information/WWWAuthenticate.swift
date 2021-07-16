//
// Created by Andreas Bauer on 08.07.21.
//

import Apodini
import Vapor

/// Implementation of the `WWW-Authenticate` header as defined in
/// https://datatracker.ietf.org/doc/html/rfc7235#section-4.1
public struct WWWAuthenticate: HTTPInformation {
    public static let header: String = "WWW-Authenticate"

    // TODO ensure uniqueness via OrderedSet?
    private let _value: [Challenge]

    public var value: [Challenge] {
        // TODO can we easily support parsing?
        precondition(!_value.isEmpty, "Parsing WWWAuthenticate from string is currently unsupported")
        return _value
    }

    public var rawValue: String

    public init?(rawValue: String) {
        self.rawValue = rawValue
        // parsing WWW Authenticate headers from string is currently unsupported
        // we encode that with an empty array!
        self._value = []
    }

    public init(_ value0: Challenge, _ values: Challenge...) {
        self.init([value0] + values)
    }

    public init(_ value: [Challenge]) {
        precondition(!value.isEmpty)
        self._value = value
        self.rawValue = value.rawValue
    }

    public func merge(with information: WWWAuthenticate) -> WWWAuthenticate {
        WWWAuthenticate(value.merge(with: information.value))
    }
}

extension WWWAuthenticate {
    public struct AuthenticationParameter {
        public var key: String
        public var value: String

        public var rawValue: String {
            let escaped = value.replacingOccurrences(of: "\"", with: "\\\"")

            // check if things need to be quoted
            if value.contains(where: { $0 == " " || $0 == "\"" }) {
                return "\(key)=\"\(escaped)\""
            } else {
                return "\(key)=\(value)"
            }
        }

        public init(key: String, value: String) {
            self.key = key
            self.value = value
        }
    }
}

extension WWWAuthenticate {
    public struct Challenge {
        public let scheme: String
        public let parameters: [AuthenticationParameter]

        public var rawValue: String {
            if parameters.isEmpty {
                return scheme
            } else {
                return "\(scheme) " + parameters
                    .map { $0 .rawValue }
                    .joined(separator: ", ")
            }
        }

        public init(scheme: String, parameters: AuthenticationParameter...) {
            self.scheme = scheme
            self.parameters = parameters
        }

        public init(scheme: String, parameters: [AuthenticationParameter]) {
            self.scheme = scheme
            self.parameters = parameters
        }
    }
}

public extension Array where Element == WWWAuthenticate.Challenge {
    var rawValue: String {
        map { $0.rawValue }
            .joined(separator: ", ")
    }

    func merge(with array: Self) -> Self {
        var result: [WWWAuthenticate.Challenge] = self

        for entry in array {
            if let index = result.firstIndex(where: { $0.scheme == entry.scheme }) {
                result.remove(at: index)
                result.insert(entry, at: index)
            } else {
                result.append(entry)
            }
        }

        return result
    }
}
