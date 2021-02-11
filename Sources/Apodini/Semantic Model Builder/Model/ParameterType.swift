//
// Created by Andreas Bauer on 12.01.21.
//

/// `Parameter` categorization needed for certain interface exporters (e.g., HTTP-based).
public enum ParameterType {
    /// Lightweight parameters are any parameters which are
    /// considered to be lightweight in some sort of way.
    /// This is the default parameter type for any primitive type properties.
    /// `LosslessStringConvertible` is a required protocol for such parameter types.
    case lightweight
    /// Parameters which transport some sort of more complex data.
    case content
    /// This parameter types represent parameters which are considered path parameters.
    /// Such parameters have a matching parameter in the `[EndpointPath]`.
    /// Such parameters are required to conform to `LosslessStringConvertible`.
    case path
}

extension ParameterType: CustomStringConvertible {
    public var description: String {
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
