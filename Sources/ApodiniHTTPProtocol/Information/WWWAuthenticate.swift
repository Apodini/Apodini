//
// Created by Andreas Bauer on 08.07.21.
//

import Apodini
import Vapor

/// Implementation of the `WWW-Authenticate` header as defined in
/// https://datatracker.ietf.org/doc/html/rfc7235#section-4.1
public struct WWWAuthenticate: HTTPInformation {
    public static let header: String = "WWW-Authenticate"

    private let _value: [Challenge]

    public var value: [Challenge] {
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
    /// Represents a ``WWWAuthenticate`` ``Challenge``.
    public struct Challenge {
        /// The scheme.
        public let scheme: String
        /// The parameters associated with the ``Challenge``.
        public let parameters: [AuthenticationParameter]

        /// The raw string value of the ``Challenge``.
        public var rawValue: String {
            if parameters.isEmpty {
                return scheme
            } else {
                return "\(scheme) " + parameters
                    .map { $0 .rawValue }
                    .joined(separator: ", ")
            }
        }

        /// Initializes a new ``Challenge``.
        /// - Parameters:
        ///   - scheme: The challenge scheme.
        ///   - parameters: The associated parameters.
        public init(scheme: String, parameters: AuthenticationParameter...) {
            self.scheme = scheme
            self.parameters = parameters
        }

        /// Initializes a new ``Challenge``.
        /// - Parameters:
        ///   - scheme: The challenge scheme.
        ///   - parameters: The associated parameters.
        public init(scheme: String, parameters: [AuthenticationParameter]) {
            self.scheme = scheme
            self.parameters = parameters
        }
    }
}

extension WWWAuthenticate {
    /// A single ``AuthenticationParameter`` of a ``Challenge``
    public struct AuthenticationParameter {
        /// The key of the parameter
        public var key: String
        /// The value of the parameter
        public var value: String

        /// The raw string value representation of the ``AuthenticationParameter``
        public var rawValue: String {
            let escaped = value.replacingOccurrences(of: "\"", with: "\\\"")

            // check if things need to be quoted
            if value.contains(where: { $0 == " " || $0 == "\"" }) {
                return "\(key)=\"\(escaped)\""
            } else {
                return "\(key)=\(value)"
            }
        }

        /// Initializes a new ``AuthenticationParameter``.
        /// - Parameters:
        ///   - key: The key of the parameter.
        ///   - value: The value of the parameter.
        public init(key: String, value: String) {
            self.key = key
            self.value = value
        }
    }
}

public extension Array where Element == WWWAuthenticate.Challenge {
    /// The raw string value representation of a ``WWWAuthenticate/Challenge`` array.
    var rawValue: String {
        map { $0.rawValue }
            .joined(separator: ", ")
    }

    /// Reduce this ``WWWAuthenticate/Challenge`` array with another.
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
