//
// This source file is part of the Apodini open source project
// 
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//
struct HideLinkContextKey: OptionalContextKey {
    typealias Value = [Operation]
}

public struct HideLinkModifier: PathComponentModifier {
    let pathComponent: _PathComponent
    // defines if only certain endpoints with certain Operations should be hidden
    let operations: [Operation]

    init(_ pathComponent: PathComponent, _ operations: [Operation] = Operation.allCases) {
        self.pathComponent = pathComponent.toInternal()
        self.operations = operations
    }

    func accept<Parser: PathComponentParser>(_ parser: inout Parser) {
        parser.addContext(HideLinkContextKey.self, value: operations)
        pathComponent.accept(&parser)
    }
}

extension PathComponent {
    /// A `HideLinkModifier` can be used to specify, that linking information to Endpoints
    /// defined under this `PathComponent` should be hidden for Exporter which support that.
    /// Accessibility of the Endpoint is not impacted by this modifier.
    ///
    /// - Returns: The modified `PathComponent`, now marked as hidden.
    public func hideLink() -> HideLinkModifier {
        HideLinkModifier(self)
    }

    /// A `HideLinkModifier` can be used to specify, that linking information to Endpoints
    /// defined under this `PathComponent` should be hidden for Exporter which support that.
    ///
    /// If supplied operations are supplied, only `Handler`s with the specified `Operation`
    /// are hidden of the annotated subpath.
    ///
    /// Accessibility of the Endpoint is not impacted by this modifier.
    ///
    /// - Parameter operations: When specified, hide only `Handler`s with listed `Operation`s.
    /// - Returns: The modified `PathComponent`, now marked as hidden.
    public func hideLink(of operations: Operation...) -> HideLinkModifier {
        HideLinkModifier(self, operations)
    }
}
