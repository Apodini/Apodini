//
// Created by Andreas Bauer on 11.07.21.
//

import Apodini

struct AuthenticationEnvironmentInjector<H: Handler, Element: Authenticatable>: Handler {
    private let delegate: Delegate<H>
    private let element: Element.Type

    init(_ handler: H, _ element: Element.Type = Element.self) {
        self.delegate = Delegate(handler, .required)
        self.element = element
    }

    func handle() async throws -> H.Response {
        try await delegate
            .environmentObject(AuthorizationStateContainer<Element>())
            .instance()
            .handle()
    }
}


// swiftlint:disable:next type_name
struct AuthenticationEnvironmentInjectorInitializer<Element: Authenticatable>: DelegatingHandlerInitializer {
    func instance<D: Handler>(for delegate: D) throws -> SomeHandler<Never> {
        SomeHandler(AuthenticationEnvironmentInjector(delegate, Element.self))
    }
}
