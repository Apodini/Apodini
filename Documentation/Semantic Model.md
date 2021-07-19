<!--
                  
This source file is part of the Apodini open source project

SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>

SPDX-License-Identifier: MIT
             
-->

![documentation](https://apodini.github.io/resources/markdown-labels/document_type_documentation.svg)  
# Semantic Model

The semantic model is an intermediary model that is somewhere in the middle between the web service declaration you write using the Apodini DSL and the behavior of the web service.

## Apodini's Strategy

The semantic model should provide an **exact description** for each `Exporter` for _how to export the web service_, without:
* room for interpretation
* extra information
* the `Exporter` having to make assumptions
* the `Exporter` having to calculate content
* the `Exporter` having to choose a strategy for how to express something

Instead, the semantic model should
* use the `Exporter`'s verbs
* be as small and concise as possible
* while still providing a one by one description of what should be exported

## Implementation

We use a slightly modified [Blackboard-Pattern](https://en.wikipedia.org/wiki/Blackboard_(design_pattern)) to provide a generic framework for building `Exporter`-specific semantic models while achieving high reusability but avoiding unnecessary computations at startup-time.

The standard blackboard-pattern aggregates some form of knowledge on a blackboard using knowledge-sources. The aggregation-process is controlled by a controller. In our implementation, the knowledge-items on the `Blackboard` are **instances** of `KnowledgeSource`s. The static type defines how the instance can be created from other knowledge that is available on the `Blackboard`. 

The blackboard-pattern implemented here is not an exact replica of the standard pattern. There is no defined controller, instead some initial basic knowledge is placed on the `Blackboard`s by the `SemanticModelBuilder`. Afterwards, all other `KnowledgeSource`s are initialized lazily based on the `Exporter`s' demand.

A `KnowledgeSource` can furthermore specify if it is to be initialized on a local (i.e. `Endpoint`-scoped) or global (i.e. `Application`-scoped) `Blackboard`. `LocalBlackboard` transparently also provides access to the `GlobalBlackboard`, whereas `GlobalBlackboard` provides a basic `KnowledgeSource`, which contains a list of all `LocalBlackboard`s present on the `Application`.

## API

### Using `KnowledgeSource`s

`Exporter`s can access the `LocalBlackboard` from the `Endpoint` instance passed to `export(_:)` and the `GlobalBlackboard` from the `WebServiceModel` passed to `finishedExporting(_:)`. Keep in mind that you cannot access `local` (i.e. endpoint-specific) knowledge from a global blackboard (i.e. in `finishedExporting(_:)`).

The `Blackboard` provides access to the `KnowledgeSource`-instances based on their type via a subscript:

```swift
let operation = endpoint[Operation.self]
```

If you know that the initialization of your `KnowledgeSource` might fail, you can still initialize it with graceful error handling:

```swift
do {
    let yourKnowledge = try endpoint.request(YourKnowledgeSource.self)
} catch {

}
```

### Creating `KnowledgeSource`s

If not specified otherwise, `KnowledgeSource`s have `LocationPreference.local`. That means, they are scoped on a single endpoint. In order to define a global `KnowledgeSource`, provide a custom `preference`:

```swift
public static var preference: LocationPreference { .global }
```

For implementing a `KnowledgeSource`, you only have define an initializer. Normally, you will use the standard initializer defined in the `KnowledgeSource` protocol, as it helps you to build `KnowledgeSource`-instances from an arbitrary selection of other `KnowledgeSource`s. For example, the `ResponseType` is defined by the return type of the outhermost `ResponseTransformer`, however, if there is no `ResponseTransformer` on this endpoint, the `Handler`'s return type is used.

```swift
public struct ResponseType: KnowledgeSource {
    public let type: Encodable.Type
    
    public init<B>(_ blackboard: B) throws where B: Blackboard {
        self.type = blackboard[ResponseTransformersReturnType.self].type ?? blackboard[HandleReturnType.self].type
    }
}
```

Keep in mind, however, that you cannot access endpoint-specific `KnowledgeSource`s if your `KnowledgeSource`'s `preference` is `.global`!

Apodini also defines more specialized protocols for building `KnowledgeSource`s:

`HandlerKnowledgeSource` allows for building a `KnowledgeSource` from a `Handler`-instance:
```swift
public struct HandleReturnType: HandlerKnowledgeSource {
    public let type: Encodable.Type
    
    public init<H>(from handler: H) throws where H: Handler {
        self.type = H.Response.Content.self
    }
}
```

`OptionalContextKeyKnowledgeSource` allows for building a `KnowledgeSource` based on an `OptionalContextKey`:
```swift
extension Operation: OptionalContextKeyKnowledgeSource {
    public typealias Key = OperationContextKey
    
    public init(from value: Key.Value?) {
        self = value ?? .read
    }
}
```
`ContextKeyKnowledgeSource` allows for building a `KnowledgeSource` based on an (non-optional) `ContextKey`:
```swift
extension ServiceType: ContextKeyKnowledgeSource {
    public typealias Key = ServiceTypeContextKey
    
    public init(from value: Key.Value) throws {
        self = value
    }
}
```

#### Global `KnowledgeSource`s

If you want to build global structures that connect all the different endpoints, you either need to build this structure based on the `Blackboards` `KnowledgeSource` available on the `GlobalBlackboard`, or you need to use a `KnowledgeSource` that itself builds upon that `Blackboards` knowledge.

An example for that is `WebServiceRoot`, which builds a global structure of your web service based on endpoints paths and operations:

```swift
public required init<B>(_ blackboard: B) throws where B: Blackboard {
    self.node = WebServiceComponent(parent: nil, identifier: .root, blackboards: blackboard[Blackboards.self][for: A.self])
}
```

`Blackboards` provides access to a list of `LocalBlackboard`s that are accessible for a specific `TruthAnchor`. In most cases the `TruthAnchor` will be the `Exporter` you are building the `KnowledgeSource` for. If you build a generic `KnowledgeSource`, make the `KnowledgeSource` used by your `KnowledgeSource` generic.

#### Local Access to Global `KnowledgeSource`s

If you have a `.global` `KnowledgeSource` you might want to have local access to the structure build by the `.global` `KnowledgeSource`. E.g. you can access a `WebServiceComponent` from a local `Blackboard`. This component is the one that has this exact `Blackboard` as one of its `endpoints`.

But how do you initialize this `KnowledgeSource`s locally, if they depend on a **global** structure? The answer is, you don't. Instead you delegate the initialization of the **local** `KnowledgeSource` to your **global** `KnowledgeSource`. Afterwards, you throw `KnowledgeError.instancePresent` from the **local** initializer and the `Blackboard` will automatically look for an instance of fitting type and return that one instead. E.g. for `WebServiceComponent`:

```swift
public required init<B>(_ blackboard: B) throws where B: Blackboard {
    // we make sure the WebServiceComponent that is meant to be initilaized here is created by
    // delegating to the WebServiceRoot
    _ = blackboard[WebServiceRoot<A>.self].node.findChild(for: blackboard[PathComponents.self].value, registerSelfToBlackboards: true)
    throw KnowledgeError.instancePresent
}
```
