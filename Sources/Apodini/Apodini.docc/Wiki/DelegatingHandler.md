# Delegating Handlers

Delegating Handlers

In some situations, putting all of your application logic into a single `Handler` is not practical. There might be a certain part of this logic that is reusable and required in multiple `Handler`s. You might not want to initialize certain objects before you have done some assertions. Or there is just so much going on in your `Handler` that it becomes difficult to read. In all of these situations you need a `Delegate`.

### Calling a `Delegate`

A _delegating `Handler`_ is any `Handler` that uses at least one `Delegate`. A `Delegate` wraps any `struct` and allows you to use the same functionality on that `struct` as you can use on a regular `Handler`. The element wrapped by the `Delegate` can - but doesn't have to - be a `Handler`.

Lets look at an example. This is the internal implementation of `SyncGuard`:

```swift
struct SyncGuardingHandler<D, G>: Handler where D: Handler, G: SyncGuard {
    let guarded: Delegate<D>
    let `guard`: Delegate<G>

    init(guarded: D, `guard`: G) {
        self.guarded = Delegate(guarded)
        self.guard = Delegate(`guard`)
    }
    
    func handle() throws -> D.Response {
        try `guard`().check()
        return try guarded().handle()
    }
}
```

The delegating `Handler` first evaluates the `guard` and - if that didn't throw - evaluates the `guarded` `Handler` to return its `Response`.


A `Delegate` can is called as a throwing function.

```swift
/// Prepare the wrapped delegate `D` for usage.
public func callAsFunction() throws -> D 
```

When you call this function, the `Delegate` performs all the magic to its wrapped element that Apodini uses to make all the `Property`s on `Handler` functional. It decodes the input for `@Parameter`s, injects local values into `@Environment` and `@EnvironmentObject` and makes sure all observing `Property`s actually observe their `ObservableObject`s. After you have called the `Delegate`, you can access all properties on the returned element and use its functionality.

This also means that the _lifetime_ of all `Property`s on the _delegate_ starts the first time you call the `Delegate` as a function. From there on, _unsolicited events_ events are observed. See [Handling Unsolicited Events](./Handling-Unsolicited-Events) for more information.

_NOTE: Mutating changes on the returned element are not persisted to the next evaluation of the delegating `Handler`._

Of course applying all this complex logic may result in errors. That is why calling the `Delegate` may throw. While in most cases you'll just pass those errors down, you could check for decoding errors here and try a different `Delegate` if the fist one fails.

### Manipulating `Delegate`

`Delegate` provides functionality for the _delegating `Handler`_ to manipulate its contained element **before** calling it. Those changes are persisted across evaluations of the _delegating `Handler`_.

```swift
struct SomeDelegatingHandler: Handler {
    let delegate = Delegate(SomeHandler())

    @Parameter var someParameter: String

    @Environment(\My.observableService) var observableService
    
    func handle() throws -> SomeHandler.Response {
        return try delegate
                        // sets the specified `Binding` on `SomeHandler` to a `.constant()` value
                        .set(\.$someStringBinding, to: someParameter)
                        // sets the specified `ObservedObject` on `SomeHandler` to the given value
                        .setObservable(\.$observable, to: observableService.getObservable(for: someParameter))
                        // injects the given value (identified by the given `KeyPath`) into the local environment
                        .environment(\My.name, someParameter)
                        // injects the given value (identified by its type) into the local environment
                        .environmentObject(someParameter)()
    }
}
```

While `set` and `setObservable` only work if you know the concrete type of your _delegate_, `environment` and `environmentObject` can be used everywhere and are applied throughout the whole hierarchy of delegation. That is, if `SomeHandler` would also have a `Delegate`, an `@EnvironmentObject` of type `String` on that `Delegate`'s wrapped element could still access the ` `someParameter`, if `SomeHandler` doesn't override it.

### Building Generic Delegating `Handler`s

While writing a _delegating `Handler`_ for a specific `Handler` is fine in many contexts, you may find yourself in a situation where you need a more generic solution.

`DelegationModifier` allows you to add _delegating `Handler`s_ on `HandlerModifier`s or even on any `Component`.

`Guard`s are one example that can be used on any `Component`:

```swift
var content: some Component {
    Group {
        Group {
            Text("Hello")
                .guard(OneGuard())
        }.guard(OtherGuard())
    }.guard(GuardThatIsNotEvenUsed())
     .resetGuards()
}
```

You can build your own modifier such as `.guard(_:)` using `.delegated(by: )`:

```swift
extension Component {
    /// Use a `DelegatingHandlerInitializer` to create a fitting delegating `Handler` for each of the `Component`'s endpoints.
    /// All instances created by the `initializer` can delegate evaluations to their respective child-`Handler` using `Delegate`.
    /// - Parameter prepend: If set to `true`, the modifier is prepended to all other calls to `delegated` instead of being appended as usual.
    /// - Note: `prepend` should only be used if `I.Response` is `Self.Response` or `Self` is no `Handler`.
    public func delegated<I: DelegatingHandlerInitializer>(by initializer: I, prepend: Bool = false) -> DelegationModifier<Self, I>
}
```
Usually, you want to have _delegating `Handler`s_ evaluated in the same order they are defined on the `Component`-tree. However, some - such as `Guard`s - are always to be evaluated before all others. In that case you can set `prepend` to `true`.

The more interesting part is the `initializer`. It is called once for each endpoint that is modified, i.e. that lives on the `Component` you use the `Modifier` on.

```swift
public protocol DelegatingHandlerInitializer: AnyDelegatingHandlerInitializer {
    associatedtype Response: ResponseTransformable
    
    /// Build a paritally type-erasured `Handler`-instance that delegates to the given `delegate`.
    func instance<D: Handler>(for delegate: D) throws -> SomeHandler<Response>
}
```

The `Response` type is only relevant to enforce that the modifier you are creating can only be used in the correct context.

Usually, if you want to manipulate the _delegate's_ `Response` you will impose certain restrictions on your modifier.

E.g. the `.response(_: )` modifier is only available where the `Response` type matches the `responseTransformer`'s input type. 

```swift
extension Handler {
    public func response<T: ResponseTransformer>(
        _ responseTransformer: T
    ) -> DelegationModifier<Self, ResponseTransformingHandlerInitializer<T>> where Self.Response.Content == T.InputContent
}
```

Thus, if you want you modifier to be usable on `HandlerModifier`s, make sure you specify the correct `Response` type on your `DelegatingHandlerInitializer` as it is reflected by the `.delegated(by:) modifier.

In any other context, the `Response` does not matter. You can set it to `Never`.

`Guard` does this in its `Component.guard(_:)` function:
```swift
extension Component {
    public func `guard`<G: Guard>(_ guard: G) -> DelegationModifier<Self, GuardingHandlerInitializer<G, Never>>
}
```

## Topics

### <!--@START_MENU_TOKEN@-->Group<!--@END_MENU_TOKEN@-->

- <!--@START_MENU_TOKEN@-->``Symbol``<!--@END_MENU_TOKEN@-->
