import Foundation

public enum WebSocketParameterMode: PropertyOption {
    case constant
    case stream
}

extension PropertyOptionKey where Property == ParameterOptionNameSpace, Option == WebSocketParameterMode {
    static let webSocket = PropertyOptionKey<ParameterOptionNameSpace, WebSocketParameterMode>()
}

extension AnyPropertyOption where Property == ParameterOptionNameSpace {
    public static func webSocket(_ mode: WebSocketParameterMode) -> AnyPropertyOption<ParameterOptionNameSpace> {
        return AnyPropertyOption(key: .webSocket, value: mode)
    }
}
