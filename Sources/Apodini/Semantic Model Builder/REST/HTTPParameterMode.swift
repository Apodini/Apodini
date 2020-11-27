import Foundation

public enum HTTPParameterMode: PropertyOption {
    case body
    case path
    case query
}

extension PropertyOptionKey where Property == ParameterOptionNameSpace, Option == HTTPParameterMode {
    static let http = PropertyOptionKey<ParameterOptionNameSpace, HTTPParameterMode>()
}

extension AnyPropertyOption where Property == ParameterOptionNameSpace {
    public static func http(_ mode: HTTPParameterMode) -> AnyPropertyOption<ParameterOptionNameSpace> {
        return AnyPropertyOption(key: .http, value: mode)
    }
}
