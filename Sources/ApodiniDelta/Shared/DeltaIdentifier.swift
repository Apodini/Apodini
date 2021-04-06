//
//  File.swift
//  
//
//  Created by Eldi Cano on 28.03.21.
//

import Foundation

/// A protocol, that requires conforming objects to introduce a `DeltaIdentifier` property
protocol DeltaIdentifiable {
    var deltaIdentifier: DeltaIdentifier { get }
}

/// A `DeltaIdentifier` uniquely identifies an object in ApodiniDelta
struct DeltaIdentifier: Value, RawRepresentable {
    let rawValue: String

    init(rawValue: String) {
        self.rawValue = rawValue
    }

    init(_ rawValue: String) {
        self.init(rawValue: rawValue)
    }
    
    init<R: RawRepresentable>(_ rawRepresentable: R) where R.RawValue == String {
        self.rawValue = rawRepresentable.rawValue
    }

    init(from decoder: Decoder) throws {
        rawValue = try decoder.singleValueContainer().decode(String.self)
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
