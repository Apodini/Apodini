//
// Created by Andi on 05.01.21.
//

struct HideLinkContextKey: ContextKey {
    static var defaultValue = false

    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = nextValue()
    }
}

public struct HideLinkModifier: PathComponentModifier {
    let pathComponent: _PathComponent

    init(_ pathComponent: PathComponent) {
        self.pathComponent = toInternalPathComponent(pathComponent)
    }

    func accept<Parser: PathComponentParser>(_ parser: inout Parser) {
        parser.addContext(HideLinkContextKey.self, value: true)
        pathComponent.accept(&parser)
    }
}

extension PathComponent {
    /// A `HideLinkModifier` can be used to specify, that linking information to Endpoints
    /// defined under this `PathComponent` should be hidden for Exporter which support that.
    /// Accessibility of the Endpoint is not impacted by this modifier
    /// - Returns: The modified `PathComponent`, now marked as hidden
    public func hideLink() -> HideLinkModifier {
        HideLinkModifier(self)
    }
}
