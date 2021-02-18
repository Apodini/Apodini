//
//  AnyEncodable.swift
//  
//
//  Created by Paul Schmiedmayer on 1/4/21.
//

import Foundation


public struct AnyEncodable: Encodable {
    public let wrappedValue: Encodable
    
    public init(_ wrappedValue: Encodable) {
        self.wrappedValue = wrappedValue
    }
    
    public func encode(to encoder: Encoder) throws {
        try wrappedValue.encode(to: encoder)
    }
}

extension AnyEncodable {
    public func typed<T: Encodable>(_ type: T.Type = T.self) -> T? {
        guard let anyEncodableWrappedValue = wrappedValue as? AnyEncodable else {
            return wrappedValue as? T
        }
        return anyEncodableWrappedValue.typed(T.self)
    }
}


public protocol AnyEncoder {
    func encode<T: Encodable>(_ value: T) throws -> Data
}

extension JSONEncoder: AnyEncoder {}




// MARK: Null

// was intended as a Codable-conformant NSNull implemnentation. can we get rid of this?
public struct Null: Codable {
    public init() {}
    
    public init(from decoder: Decoder) throws {
        let wasNil = try decoder.singleValueContainer().decodeNil()
        if !wasNil {
            throw NSError(domain: "Apodini", code: 0, userInfo: [NSLocalizedDescriptionKey: "wasnt nil"])
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encodeNil()
    }
}




// MARK: Other


extension Encodable {
    public func encodeToJSON(outputFormatting: JSONEncoder.OutputFormatting = []) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = outputFormatting
        return try encoder.encode(self)
    }
    
    public func writeJSON(
        to url: URL,
        encoderOutputFormatting: JSONEncoder.OutputFormatting = [.prettyPrinted],
        writingOptions: Data.WritingOptions = []
    ) throws {
        let data = try encodeToJSON(outputFormatting: encoderOutputFormatting)
        try data.write(to: url, options: writingOptions)
    }
}


extension Decodable {
    public init(decodingJSON data: Data) throws {
        self = try JSONDecoder().decode(Self.self, from: data)
    }
    
    public init(decodingJSONAt url: URL) throws {
        let data = try Data(contentsOf: url)
        self = try JSONDecoder().decode(Self.self, from: data)
    }
}
