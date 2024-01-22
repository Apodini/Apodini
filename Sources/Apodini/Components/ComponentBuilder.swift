//
// This source file is part of the Apodini open source project
// 
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//


@resultBuilder
public enum ComponentBuilder {
    // Support for else-less if statements
    public static func buildOptional<C: Component>(_ component: C?) -> C? {
        component
    }
    
    // Support for if-else and switch statements
    public static func buildEither<C: Component>(first: C) -> C {
        first
    }
    public static func buildEither<C: Component>(second: C) -> C {
        second
    }
    
    
    // The first element in a Component gets passed trough as-is.
    public static func buildPartialBlock<C: Component>(first: C) -> C {
        first
    }
    
    // This overload gets used for the second element in a Component.
    // We combine it with the first, and wrap it in a TupleComponent.
    // Note that we can't return `some Component` here, since that'd
    // break the overload resolution for the ComponentBuilder, and
    // would cause all `buildPartialBlock` calls to go through this
    // function (which is not what we want).
    public static func buildPartialBlock<C0: Component, C1: Component>(
        accumulated: C0,
        next: C1
    ) -> TupleComponent<C0, C1> {
        TupleComponent(accumulated, next)
    }
    
    /// Builds up a ``Component``'s body.
    ///
    /// This is the main overload for building up ``Component`` bodies. It gets called for every additional element in a ``Component``
    /// that comes after the second (i.e., after the elements in the ``Component`` have been wrapped in a ``TupleComponent``).
    /// We need this overload to keep the Component type being built up via the ``ComponentBuilder`` flat.
    /// Consider the following example:
    ///
    ///     @ComponentBuilder
    ///     var body: some Component {
    ///         A()
    ///         B()
    ///         C()
    ///     }
    ///
    /// Without this overload, the type of the resulring ``Component`` would be `TupleComponent<TupleComponent<TupleComponent<X, A>, B>, C>`.
    /// But with this overload, it instead is `TupleComponent<A, B, C>`.
    /// (Maintaining the flatness of the resulting structure is important for more reasons than just aesthetics and performance,
    /// since it also determines e.g. the internal identifiers assigned to individual ``Handler``s by the semantic model.)
    public static func buildPartialBlock<each C: Component, Next: Component>(
        accumulated: TupleComponent<repeat each C>,
        next: Next
    ) -> TupleComponent<repeat each C, Next> {
        TupleComponent(repeat each accumulated.component, next)
    }
    
    
    // This one is needed because we also implement `buildFinalResult` for the case
    // where the component is `Never`, but we of course also want to support Component bodies
    // with a resulting type of something other than `Never`.
    public static func buildFinalResult<C: Component>(_ component: C) -> C {
        component
    }
    
    
    // MARK: `Never` handling
    
    // Support for components that contain at least one expression of type `Never`.
    // This is required to properly support components that contain a `fatalError`,
    // and allows us to efficiently propagate that `Never` through the entire tree.
    public static func buildPartialBlock(first: Never) -> Never {}
    public static func buildPartialBlock(accumulated: Never, next: some Component) -> Never {}
    public static func buildPartialBlock(accumulated: some Component, next: Never) -> Never {}
    public static func buildFinalResult(_ component: Never) -> Never {}
}
