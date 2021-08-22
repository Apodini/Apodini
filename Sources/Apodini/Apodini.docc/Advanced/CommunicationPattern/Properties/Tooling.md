# Tooling

Description service structure for endpoints.

<!--
                  
This source file is part of the Apodini open source project

SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>

SPDX-License-Identifier: MIT
             
-->

## Component

A service consists of multiple endpoints. Apodini provides a DSL that allows to define the service's structure using `Component`s. `Component`s have a recursive `content: some Component` property that is used to build a `Component`-stack. This stack is determined on startup and may not change during runtime. An endpoint is created where the `Component`'s `content` is `Never`. Such `Component`s are `Handler`s. Both, input- and output-type of an endpoint (i.e. `Handler`) are fixed at startup.

## Handler

`Handler`s hold the implementation of an endpoint's logic. A `Handler` has an associated type `Response: ResponseTransformable`. Implementations of the `Handler` protocol are `struct`s which provide a function `handle() -> some ResponseTransformable`. The `ResponseTransformable` can be one of the following:
* `Content`: an `Encodable` that is marked as `Content`, e.g. `Int`
* `Response<E: Encodable>`: an enum that can either be `nothing`, `send(E)`, `end` or `final(E)`.
* An `EventLoopFuture` of either of the above.

If you provide a `Content` as your `handle()`'s return type, it is interpreted as `Response.final(handle())`

### Lifetime

In general a `Handler` is kept alive until it was evaluated to `Response.final(E)` or `Response.end`. Some exporters may enforce further rules based on the communicational patterns that are used to represent the respective endpoint. Consider the following example: An HTTP 1 based exporter must export an endpoint that returns a `Response<E>`. As the request-response pattern is the only pattern HTTP 1 supports, the exporter downgrades the endpoint to the request-response pattern. In this scenario the exporter could destruct the `Handler` after the first `Action.send(Response)`, because it cannot send more messages anyways.

### Properties

`Handler`s can use different types of `Property` variables. Apodini provides multiple implementations of this protocol that provide different functionality. The implementations are described in the following chapters. Properties on `Handler`s that are a `Property` are managed by the Apodini framework. The framework makes sure they are exclusive to one client-service connection. The developer does not have to take care of synchronization. Other properties should be used for static, globally shared content only or references to services that manage access and synchronization themselves.

### Layers of Logic

On a basic level, a declarative syntax that provides functionality through property wrappers, is very limited in the way that one property cannot depend on another one. Take the following example:

The endpoint declares a service-side stream that sends messages for a specific user with `UUID` `userId`. For that it uses two fictional property wrappers:
* `@Magic1` extracts the `userId` from the initial request and makes sure `handle` is called afterwards.
* `@Magic2` makes sure `handle` is called each time `userMessages` is updated with a `newMessage`.

```swift
struct MessageStream: Handler {

    @Magic1 var userId: UUID

    // Error: "Cannot use instance member 'userId' within property initializer; property initializers run before 'self' is available"
    @Magic2 var userMessages: MessageStore = MessageStoreService.getMessageStore(for: userId)

    func handle() -> Response<Message> {
        if let message = userMessages.newMessage {
            return .send(message)
        }
        return .nothing
    }
}
```

There are two options to solve this issue. Either `Handler`s need to be composable (even just linear delegation would be possible) or there has to be a composed `@Magic` that combines the features of `@Magic1` and `@Magic2`. Apodini must at least provide one of those options, but it could also support both, as they are compatible.

#### Composition of Handlers

A `Handler` does not have to provide a `handle()` function anymore, but can also specify a `handler` variable that points to another `Handler`. The above example would look like the following:

```swift
struct MessageStream: Handler {
    @Magic1 var userId: UUID

    var handler: Handler {
        MessageStreamOfUser(userMessages: MessageStoreService.getMessageStore(for: userId))
    }
}

struct MessageStreamOfUser: Handler {

    @Magic2 var userMessages: MessageStore

    func handle() -> Response<Message> {
        if let message = userMessages.newMessage {
            return .send(message)
        }
        return .nothing
    }
}
```

#### Composition of Property Wrappers

The developer can create custom property wrappers that are managed by Apodini. Those must extend the protocol `DynamicProperty`. The `Magic` below takes the parameter-type `UUID` so it knows what to extract from the request. In addition it takes a `transformer` so it can create the output (`observed`) from the input (`extracted`) once the extraction is complete.

The `observed` property is then exported using the `wrappedValue` of the property wrapper. Finally, the functionality of `observed` is also exported using the `projectedValue`. This makes sure the `MessageStream`'s `handle` is still called when the `MessageStore` is updated even though `@Magic2` does not live on `MessageStream` directly anymore.

```swift
@propertyWrapper
struct Magic<I, O>: DynamicProperty {
    @Magic1 private var extracted: I {
        didSet {
            self.observed = _transformer(newValue)
        }
    }

    @Magic2 private var observed: O?

    let _transformer: (I) -> O

    init(_ type: I.Type, using transformer: @escaping (I) -> O) {
        self._transformer = transformer
    }

    var wrappedValue: O {
        if let o = observed {
            return o
        }
        fatalError("You cannot access this property yet.")
    }

    var projectedValue: Magic2Projection {
        $observed
    }
}


struct MessageStream: Handler {

    @Magic(UUID.self, using: { userId in
        MessageStoreService.getMessageStore(for: userId)
    })
    var userMessages: MessageStore

    func handle() -> Response<Message> {
        if let message = userMessages.newMessage {
            return .send(message)
        }
        return .nothing
    }
}
```

## Topics

### Tooling

- <doc:MeaningOfParameter>
- <doc:MeaningOfState>
- <doc:MeaningOfObservedObject>
- <doc:MeaningOfEnvironment>
