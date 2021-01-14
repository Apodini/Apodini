//
// Created by Andi on 12.01.21.
//

/// `Parameter` categorization needed for certain interface exporters (e.g., HTTP-based).
enum ParameterType {
    case lightweight
    case content
    case path
}

extension ParameterType: CustomStringConvertible {
    var description: String {
        switch self {
        case .lightweight:
            return "lightweight"
        case .content:
            return "content"
        case .path:
            return "path"
        }
    }
}
