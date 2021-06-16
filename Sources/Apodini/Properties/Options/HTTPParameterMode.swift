import Foundation


/// An HTTP specific `PropertyOption` that indicates how the `@Parameter` property wrapper should be interpreted by interface exporters using HTTP to identify and multiplex components.
public enum HTTPParameterMode: PropertyOption {
    /// The property associated with the `@Parameter` property wrapper should be decoded from the `body` of the HTTP request
    case body
    /// The property associated with the `@Parameter` property wrapper should be decoded from the URI path of the HTTP request
    case path
    /// The property associated with the `@Parameter` property wrapper should be decoded from the URI query of the HTTP request
    case query
}

extension PropertyOptionKey where PropertyNameSpace == ParameterOptionNameSpace, Option == HTTPParameterMode {
    static let http = PropertyOptionKey<ParameterOptionNameSpace, HTTPParameterMode>()
}

extension AnyPropertyOption where PropertyNameSpace == ParameterOptionNameSpace {
    /// An HTTP specific option that indicates how the `@Parameter` property wrapper should be interpreted by interface exporters using HTTP to identify and multiplex components.
    public static func http(_ mode: HTTPParameterMode) -> AnyPropertyOption<ParameterOptionNameSpace> {
        AnyPropertyOption(key: .http, value: mode)
    }
}
