//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import AssociatedTypeRequirementsVisitor


/// How a decoder should decode dates.
public enum DateDecodingStrategy {
    struct DateDecodingError: Error, LocalizedError {
        let rawInput: String
        let decodingStrategyDesc: String
        
        init(rawInput: String, decodingStrategy: DateDecodingStrategy) {
            self.rawInput = rawInput
            self.decodingStrategyDesc = {
                switch decodingStrategy {
                case .iso8601: return "iso8601"
                case .secondsSince1970: return "secondsSince1970"
                case .secondsSinceReferenceDate: return "secondsSinceReferenceDate"
                case .custom: return "custom"
                }
            }()
        }
        
        var errorDescription: String? {
            "Unable to decode date from raw input '\(rawInput)'. Used strategy: \(decodingStrategyDesc)"
        }
    }
    
    /// Decodes `Date` objects from an ISO8601 string
    case iso8601
    /// Decodes `Date` objects from a UNIX timestamp
    case secondsSince1970
    /// Decodes `Date` objects from a timestamp relative to Foundation's reference date of 00:00:00 UTC on 1 January 2001
    case secondsSinceReferenceDate
    /// Decodes `Date` objects using a custom closure.
    case custom((String) throws -> Date)
    
    /// The "default" date decoding strategy, which interprets dates as UNIX timestamps
    /// This static variable exists to ensure that different methods and types can use a common uniform "default" date decoding strategy.
    public static let `default` = Self.secondsSince1970
    
    func decodeDate(from rawValue: String) throws -> Date {
        switch self {
        case .iso8601:
            if let date = ISO8601DateFormatter().date(from: rawValue) {
                return date
            } else {
                throw DateDecodingError(rawInput: rawValue, decodingStrategy: self)
            }
        case .secondsSince1970:
            guard let numericValue = TimeInterval(rawValue) else {
                throw DateDecodingError(rawInput: rawValue, decodingStrategy: self)
            }
            return Date(timeIntervalSince1970: numericValue)
        case .secondsSinceReferenceDate:
            guard let numericValue = TimeInterval(rawValue) else {
                throw DateDecodingError(rawInput: rawValue, decodingStrategy: self)
            }
            return Date(timeIntervalSinceReferenceDate: numericValue)
        case .custom(let decodingFn):
            return try decodingFn(rawValue)
        }
    }
}


/// A rather crude, simple, and limited implementation of a URL query parameter value decoder
struct URLQueryParameterValueDecoder {
    let dateDecodingStrategy: DateDecodingStrategy
    
    init(dateDecodingStrategy: DateDecodingStrategy = .default) {
        self.dateDecodingStrategy = dateDecodingStrategy
    }
    
    func decode<T: Decodable>(_: T.Type, from rawValue: String) throws -> T {
        if T.self == Date.self {
            return try dateDecodingStrategy.decodeDate(from: rawValue) as! T
        }
        let decoder = _Decoder(rawValue: rawValue, dateDecodingStrategy: self.dateDecodingStrategy)
        return try T(from: decoder)
    }
}


private struct _Decoder: Decoder {
    // This decoder doesn't access nested values, therefore we always operate on an empty path.
    let codingPath: [CodingKey] = []
    let userInfo: [CodingUserInfoKey: Any] = [:]
    
    let rawValue: String
    let dateDecodingStrategy: DateDecodingStrategy
    
    func container<Key: CodingKey>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> {
        fatalError("Not supported")
    }
    
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        fatalError("Not supported")
    }
    
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        SingleValueContainer(rawValue: rawValue, codingPath: [], dateDecodingStrategy: dateDecodingStrategy)
    }
    
    
    private struct SingleValueContainer: SingleValueDecodingContainer {
        let rawValue: String
        var codingPath: [CodingKey]
        let dateDecodingStrategy: DateDecodingStrategy
        
        init(rawValue: String, codingPath: [CodingKey], dateDecodingStrategy: DateDecodingStrategy) {
            self.rawValue = rawValue
            self.codingPath = codingPath
            self.dateDecodingStrategy = dateDecodingStrategy
        }
        
        func decodeNil() -> Bool {
            rawValue.isEmpty // NOTE what about empty strings? That's absolutely fine and should not be considered a nil value.
        }
        
        func decode<T: Decodable>(_ type: T.Type) throws -> T {
            guard !(T.self is Date.Type) else {
                return try dateDecodingStrategy.decodeDate(from: rawValue) as! T
            }
            if let queryParamValueDecodableTy = T.self as? URLQueryParameterValueDecodable.Type {
                if let result = queryParamValueDecodableTy.init(urlQueryParamValue: rawValue) {
                    return result as! T
                } else {
                    throw DecodingError.typeMismatch(T.self, DecodingError.Context(
                        codingPath: [],
                        debugDescription: "Unable to decode value. (\(URLQueryParameterValueDecodable.self) conformance returned nil.) Raw value: '\(rawValue)'",
                        underlyingError: nil
                    ))
                }
            } else if let losslessStringDecodableTy = T.self as? LosslessStringConvertible.Type {
                if let result = losslessStringDecodableTy.init(rawValue) {
                    return result as! T
                } else {
                    throw DecodingError.typeMismatch(T.self, DecodingError.Context(
                        codingPath: [],
                        debugDescription: "Unable to decode value. (\(LosslessStringConvertible.self) conformance returned nil.) Raw value: '\(rawValue)'",
                        underlyingError: nil
                    ))
                }
            } else {
                throw DecodingError.typeMismatch(T.self, DecodingError.Context(
                    codingPath: [],
                    debugDescription: "Unable to decode value, because '\(T.self)' conforms neither to \(URLQueryParameterValueDecodable.self), nor to \(LosslessStringConvertible.self).",
                    underlyingError: nil
                ))
            }
        }
    }
}


/// A type which can be decoded from a URL query parameter value
/// Normally, we'd simply add a `LosslessStringConvertible` conformance to a type we want to decode,
/// but in the case of standard library types w/out a clear lossless representation, that isn't really a good idea, since
/// this conformance would need to be declared public.
/// Consider the `Bool` type, for instance. The "lossless" raw values could be any of 1/0, yes/no, true/false, their abbreviations, etc.
/// Who are we to determine, for the entirety of the application and any web services using this,
/// what their boolean's "lossless" representations ought to be?
private protocol URLQueryParameterValueDecodable {
    init?(urlQueryParamValue value: String)
}


extension Bool: URLQueryParameterValueDecodable {
    init?(urlQueryParamValue value: String) {
        switch value.lowercased() {
        case "1", "true", "yes":
            self = true
        case "0", "false", "no":
            self = false
        default:
            return nil
        }
    }
}
