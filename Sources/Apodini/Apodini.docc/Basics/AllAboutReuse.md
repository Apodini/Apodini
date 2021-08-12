# All About Reuse

Despite its declarative nature, Apodini's API is really flexible and enables you to build reusable components on many different levels.

## Overview

There are a couple of primitives in Apodini that enable you to custom elements that can be easily composed to create new, unique functionality.

### DynamicProperty

``DynamicProperty``s are the simplest form of reuse. They are custom ``Property``s that are composed of other ``Property``s. Just as ``Handler``s, ``DynamicProperty``s must be structs. Imagine you build a web service that is somehow related to geography. One input you will need almost everywhere is a geolocation - a pair of latitude and longitude. Instead of defining them as separate ``Parameter``s on each and every ``Handler``, you could define a custom `Location` type.

```swift
typealias Coordinates = (latitude: Double, longitude: Double)

@propertyWrapper
struct Location: DynamicProperty {
    @Parameter var latitude: Double
    @Parameter var longitude: Double

    var wrappedValue: Coordinates {
        (latitude, longitude)
    }
}
```

You can then use this custom ``DynamicProperty`` on your ``Handler``s just as regular ``Property``s:

```swift
struct TemperatureHandler: Handler {
    @Parameter var date: Date
    
    @Location var location

    @Environment(\.temperatureService) var temperature

    func handle() async throws -> Double {
        try await temperature(date, location)
    }
}

```

Of course you can also use other ``Property``s than ``Parameter`` in ``DynamicProperty``s.

> Note: If want to be even more dynamic, you can use the ``Properties`` type. It provides the exact same features as ``DynamicProperty``, but is based on a hash map instead of a struct. This way you can dynamically calculate at startup time what ``Property``s you need as part of your custom ``Property``.

### Binding

``Binding`` works just as in SwiftUI, except it has no setter. It allows us to reuse the same ``Component`` or ``Handler`` in different contexts:

```swift
struct Greeter: Handler {
    @Binding var country: String?

    func handle() -> String {
        "Hello, \(country ?? "World")!"
    }
}

struct CountrySubsystem: Component {
    @PathParameter var country: String
    
    @Environment(\.featuredCountry) var featuredCountry: String
    
    var content: some Component {
        Greeter(country: nil)
            .description("Say 'Hello' to the World.")
        
        Group($country) {
            Greeter(country: $country.asOptional)
                .description("Say 'Hello' to a chosen country.")
        }
        Group("featured") {
            Greeter(country: $featuredCountry.asOptional)
                .description("Say 'Hello' to the currently featured country.")
        }
    }
}
```

### Delegate

In some situations, putting all of your application logic into a single ``Handler`` is not practical. There might be a certain part of this logic that is reusable and required in multiple ``Handler``s. You might not want to initialize certain objects before you have done some assertions. Or there is just so much going on in your ``Handler`` that it becomes difficult to read. In all of these situations you need a ``Delegate``.

#### Calling a Delegate

A _delegating ``Handler``_ is any ``Handler`` that uses at least one ``Delegate``. A ``Delegate`` wraps any struct and allows you to use the same functionality on that struct as you can use on a regular ``Handler``. The element wrapped by the ``Delegate`` can - but doesn't have to - be a ``Handler``. ``Delegate`` itself must always be used on a ``Handler`` - or any type that is wrapped by a ``Delegate``.

A ``Delegate`` has a throwing ``Delegate/instance()`` function. This function returns the wrapped element. When you call this function, the ``Delegate`` performs all the magic to its wrapped element that Apodini uses to make all the ``Property``s on ``Handler`` functional. For example, that is where it decodes the input for ``Parameter``s. After you have called the `Delegate`, you can access all properties on the returned element and use its functionality.

Of course applying all this complex logic may result in errors. That is why calling the ``Delegate/instance()`` function may throw. While in most cases you'll just pass those errors down, you could check for decoding errors here and try a different ``Delegate`` if the fist one fails.

Let's look at an example.

```swift
struct OrderProduct: Handler {
    // ...
}

struct WaitForProduct: Handler {
    // ...
}

struct ProductPage: Handler {
    @Parameter var productID: UUID

    @Environment(\.productService) var productService

    var wait: Delegate(WaitForProduct())

    var order: Delegate(OrderProduct())

    func handle() throws -> ProductInfo {
        guard !productService.isPreReleaseItem(productID) else {
            return .preReleaseInfo(try wait.instance().handle())
        }

        return .orderInfo(try order.instance().handle())
    }
}
```

This ``Handler`` returns the contents for an online shop's product page. If the product hasn't launched yet according to the `productService`, the `ProductPage` delegates handling to the `WaitForProduct` ``Handler``. The latter returns information such as when the product is going to launch. If the product is already available, the call is delegated to the `OrderProduct` ``Handler``, which returns information relevant to actually ordering the product.



#### Manipulating `Delegate`

``Delegate`` provides functionality for the _delegating_ ``Handler`` to manipulate its contained element **before** calling its ``Delegate/instance()`` function. Those changes are persistent.

```swift
struct SomeDelegatingHandler: Handler {
    let delegate = Delegate(SomeHandler(), .required)

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
                        .environmentObject(someParameter)
                        .instance()
    }
}
```

While ``Delegate/set(_:to:)`` and ``Delegate/setObservable(_:to:)`` only work if you know the concrete type of your _delegate_, ``Delegate/environment(_:_:)-mc6t`` and ``Delegate/environmentObject(_:)`` can be used everywhere and are applied throughout the whole hierarchy of delegation. That is, if `SomeHandler` would also have a ``Delegate``, an ``Environment`` targeting `\My.name` on that ``Delegate``'s wrapped element could still access the ` `someParameter`, if `SomeHandler` doesn't override it.


> Tip: ``EnvironmentObject`` works just as ``Environment``, except it solely uses the type for identification and not a `KeyPath`. Furthermore, ``EnvironmentObject`` does have no access to the global environment, but solely to objects injected via ``Delegate``'s ``Delegate/environmentObject(_:)`` function.

You may have noticed the ``Optionality/required`` value passed into the ``Delegate``'s initializer. This parameter has no effect on the runtime-behavior of the ``Delegate``. Instead, it allows you to modify how potential documentation exporters perceive the ``Parameter``s hidden inside this ``Delegate``. Without that parameter the framework assumes that calling this ``Delegate`` is not a necessity and all wrapped ``Parameter``s are assumed to be optional. As a rule of thumb, you should always add the `.required` argument if there all paths trough your ``Handler/handle()-3440f`` function either call the ``Delegate``'s ``Delegate/instance()`` function or throw an error.

<!-- > Note: If you want to know more about ``ObservedObject``, check out <doc:StatefulHandlers> --> 


### DelegationModifier

``Delegate`` on is not a feature you want to use everywhere. It lets you implement almost every form of reuse thinkable in Apodini, however it is also rather complex to use. That is why in most cases you don't use it directly. Instead you use predefined or custom ``DelegationModifier``s. That is a special type of ``Modifier``, which wraps the ``Handler``s defined on the inner ``Component``s in another ``Handler`` using a ``Delegate``. While that sounds complex, the usage isn't:

```swift
struct ValidateAPIKey: Guard {
    @Parameter var apiKey: String

    @Environment(\.apiKeyService) var apiKeyService

    func check() throws {
        try apiKeyService.check(apiKey)
    }
}

struct SomeProtectedComponent: Component {
    var content: some Component {
        Group("api") {
            Group("featureOne") {
                FirstHandler()
            }
            // ...
        }.guard(ValidateAPIKey())
    }
}
```

The `.guard(_:)` function defined on ``Handler`` and ``Component`` takes a ``Guard``. In the example, `FirstHandler` - and all other ``Handler``s defined in the `"api"` ``Group`` - are protected by the `ValidateAPIKey` ``Guard``. The `.guard(_:)` function takes the given ``Guard`` and wraps the inner ``Handler``s into a _delgating_ ``Handler``, which first executes ``Guard/check()`` and only delegates to the wrapped ``Handler``, if ``Guard/check()`` didn't throw an error.

Another type that is based on ``DelegationModifier`` is ``ResponseTransformer``. It does quite the opposite of ``Guard``. It first evaluates the wrapped ``Handler`` and then transforms its result using the ``ResponseTransformer/transform(content:)`` function. You can wrap ``Handler``s in a ``ResponseTransformer`` using the ``Handler/response(_:)`` modifier.

<!-- TODO: link to metadata -->
<!-- TODO: link to authentication -->
<!-- TODO: link to logging, metrics? -->

> Note: If you want information on how to implement your own ``DelegationModifier`` extensions, check out the advanced document on <doc:HandlerDelegation>.

## Topics

### DynamicProperty

- ``DynamicProperty``
- ``Property``
- ``Properties``
- ``TypedProperties``

### Binding

- ``Binding``
- ``Environment``
- ``Parameter``
- ``PathParameter``
- ``Binding/constant(_:)``

### Delegate

- ``Delegate``
- ``Environment``
- ``EnvironmentObject``
- ``ObservedObject``
- ``Binding``

### DelegationModifier

- ``DelegationModifier``
- ``Guard``
- ``ResponseTransformer``
- ``Delegate``
- ``DelegatingHandlerInitializer``
