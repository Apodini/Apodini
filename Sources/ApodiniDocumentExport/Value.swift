import Foundation

/// A protocol that requires conformance to `Codable` and `Hashable` (also `Equatable`)
public protocol Value: Codable, Hashable {}

extension Array: Value where Element: Value {}
