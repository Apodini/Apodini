import Foundation
import PathKit

/// Represent different cases of file extensions
public enum FileExtension: CustomStringConvertible {
    /// JSON
    case json
    /// YAML
    case yaml
    /// Other
    case other(String)
    
    /// String representation this extension
    public var description: String {
        switch self {
        case .json: return "json"
        case .yaml: return "yaml"
        case let .other(value): return value
        }
    }
}

public extension String {
    /// Returns lhs after appending `.` and `description` of `rhs`
    static func + (lhs: Self, rhs: FileExtension) -> Self {
        lhs + "." + rhs.description
    }
}

public extension Path {
    /// Indicates whether the path corresponds to a file with the corresponding extension
    func `is`(_ fileExtension: FileExtension) -> Bool {
        `extension` == fileExtension.description
    }
}
