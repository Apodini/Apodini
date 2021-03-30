//
//  File.swift
//  
//
//  Created by Eldi Cano on 28.03.21.
//

import Foundation

/// A `DeltaIdentifier` uniquely identifies an object in ApodiniDelta
struct DeltaIdentifier: Value, RawRepresentable {
    let rawValue: String

    init(rawValue: String) {
        self.rawValue = rawValue
    }

    init(_ rawValue: String) {
        self.init(rawValue: rawValue)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        rawValue = try container.decode(String.self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

extension DeltaIdentifier: CustomStringConvertible {
    public var description: String { rawValue }
}

extension DeltaIdentifier {
    func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }
}

extension DeltaIdentifier {
    static func == (lhs: DeltaIdentifier, rhs: DeltaIdentifier) -> Bool {
        lhs.rawValue == rhs.rawValue
    }
}
