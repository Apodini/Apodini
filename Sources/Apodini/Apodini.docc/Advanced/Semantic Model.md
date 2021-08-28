# Semantic Model

The semantic model is an intermediary model that is somewhere in the middle between the web service declaration you write using the Apodini DSL and the behavior of the web service.

<!--
                  
This source file is part of the Apodini open source project

SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>

SPDX-License-Identifier: MIT
             
-->

## Overview

The semantic model should provide an **exact description** for each ``InterfaceExporter`` for _how to export the web service_, without:
* room for interpretation
* extra information
* the exporter having to make assumptions
* the exporter having to calculate content
* the exporter having to choose a strategy for how to express something

Instead, the semantic model should
* use the exporter's verbs
* be as small and concise as possible
* while still providing a one by one description of what should be exported

### Implementation

We use a slightly modified [Blackboard-Pattern](https://en.wikipedia.org/wiki/Blackboard_(design_pattern)) to provide a generic framework for building exporter-specific semantic models while achieving high reusability but avoiding unnecessary computations at startup-time.

The standard blackboard-pattern aggregates some form of knowledge on a blackboard using knowledge-sources. The aggregation-process is controlled by a controller. In our implementation, the knowledge-items on the ``Blackboard`` are **instances** of ``KnowledgeSource``s. The static type defines how the instance can be created from other knowledge that is available on the `Blackboard`. 

The blackboard-pattern implemented here is not an exact replica of the standard pattern. There is no defined controller, instead some initial basic knowledge is placed on the ``Blackboard``s by the internal `SemanticModelBuilder`. Afterwards, all other ``KnowledgeSource``s are initialized lazily based on the exporters' demand.

A ``KnowledgeSource`` can furthermore specify if it is to be initialized on a local (i.e. ``Endpoint``-scoped) or global (i.e. ``Application``-scoped) ``Blackboard``. The local blackboard transparently also provides access to the global blackboard, whereas the global one provides a basic ``KnowledgeSource`` called ``Blackboards``, which contains a list of all local ``Blackboard``s present on the ``Application``.

### API

#### Using KnowledgeSources

``InterfaceExporter``s can access the **local** ``Blackboard`` from the ``Endpoint`` instance passed to ``InterfaceExporter/export(_:)`` and the **global** one from the ``WebServiceModel`` passed to ``InterfaceExporter/finishedExporting(_:)-9eep3``. Keep in mind that you cannot access **local** (i.e. endpoint-specific) knowledge from a global blackboard (i.e. in ``InterfaceExporter/finishedExporting(_:)-64gse``).

The ``Blackboard`` provides access to the ``KnowledgeSource``-instances based on their type via a subscript:

```swift
let operation = endpoint[Operation.self]
```

If you know that the initialization of your ``KnowledgeSource`` might fail, you can still initialize it with graceful error handling:

```swift
do {
    let yourKnowledge = try endpoint.request(YourKnowledgeSource.self)
} catch {
    // ...
}
```

#### Creating KnowledgeSources

If not specified otherwise, a ``KnowledgeSource``'s ``KnowledgeSource/preference-8dfb0`` is ``LocationPreference/local``. That means, they are scoped on a single endpoint. In order to define a global ``KnowledgeSource``, override ``KnowledgeSource/preference-69cks``:

```swift
public static var preference: LocationPreference { .global }
```

For implementing a ``KnowledgeSource``, you only have define an initializer. Normally, you will use the standard initializer defined in the ``KnowledgeSource`` protocol, as it helps you to build ``KnowledgeSource``-instances from an arbitrary selection of other ``KnowledgeSource``s.

> Note: Keep in mind, however, that you cannot access endpoint-specific ``KnowledgeSource``s if your ``KnowledgeSource``'s ``KnowledgeSource/preference-8dfb0`` is ``LocationPreference/global``!

Apodini also defines more specialized protocols for building ``KnowledgeSource``s:

``HandlerKnowledgeSource`` allows for building a ``KnowledgeSource`` from a ``Handler``-instance:
```swift
public struct HandleReturnType: HandlerKnowledgeSource {
    public let type: Encodable.Type
    
    public init<H: Handler, B: Blackboard>(from handler: H, _ blackboard: B) throws {
        self.type = H.Response.Content.self
    }
}
```

``OptionalContextKeyKnowledgeSource`` allows for building a ``KnowledgeSource`` based on an `OptionalContextKey`:
```swift
extension Operation: OptionalContextKeyKnowledgeSource {
    public typealias Key = OperationContextKey
    
    public init(from value: Key.Value?) {
        self = value ?? .read
    }
}
```
``ContextKeyKnowledgeSource`` allows for building a ``KnowledgeSource`` based on a (non-optional) `ContextKey`:
```swift
extension ServiceType: ContextKeyKnowledgeSource {
    public typealias Key = ServiceTypeContextKey
    
    public init(from value: Key.Value) throws {
        self = value
    }
}
```

##### Global KnowledgeSources

If you want to build global structures that connect all the different endpoints, you either need to build this structure based on the ``Blackboards`` ``KnowledgeSource`` available on the **global** blackboard (i.e. ``WebServiceModel``), or you need to use a ``KnowledgeSource`` that itself builds upon that ``Blackboards`` knowledge.

An example for that is ``WebServiceRoot``, which builds a global structure of your web service based on endpoints paths and operations:

```swift
public required init<B>(_ blackboard: B) throws where B: Blackboard {
    self.node = WebServiceComponent(parent: nil, identifier: .root, blackboards: blackboard[Blackboards.self][for: A.self])
}
```

``Blackboards`` provides access to a list of local blackboards that are accessible for a specific ``TruthAnchor``. In most cases the ``TruthAnchor`` will be the ``InterfaceExporter`` you are building the ``KnowledgeSource`` for. If you build a generic ``KnowledgeSource``, make the ``TruthAnchor`` used by your ``KnowledgeSource`` generic.

##### Local Access to Global KnowledgeSources

If you have a ``LocationPreference/global`` ``KnowledgeSource`` you might want to have local access to the structure build by the ``LocationPreference/global`` ``KnowledgeSource``. E.g. you can access a ``WebServiceComponent`` from a local ``Blackboard``. This component is the one that has this exact ``Blackboard`` as one of its ``WebServiceComponent/endpoints``.

But how do you initialize this ``KnowledgeSource``s locally, if they depend on a **global** structure? The answer is, you don't. Instead you delegate the initialization of the **local** ``KnowledgeSource`` to your **global** ``KnowledgeSource``. Afterwards, you throw ``KnowledgeError/instancePresent`` from the **local** initializer and the ``Blackboard`` will automatically look for an instance of fitting type and return that one instead. E.g. for ``WebServiceComponent``:

```swift
public required init<B>(_ blackboard: B) throws where B: Blackboard {
    // we make sure the WebServiceComponent that is meant to be initialized here is created by
    // delegating to the WebServiceRoot
    _ = blackboard[WebServiceRoot<A>.self].node.findChild(for: blackboard[PathComponents.self].value, registerSelfToBlackboards: true)
    throw KnowledgeError.instancePresent
}
```

## Topics

### Basics

- ``Blackboard``
- ``KnowledgeSource``
- ``LocationPreference``
- ``Endpoint``
- ``WebServiceModel``
- ``TruthAnchor``
- ``KnowledgeError``

### Specialized KnowledgeSource Protocols

- ``HandlerKnowledgeSource``
- ``ContextKeyKnowledgeSource``
- ``OptionalContextKeyKnowledgeSource``

### Provided KnowledgeSource Implementations

- ``AnyHandlerIdentifier``
- ``DelegateFactory``
- ``HandlerDescription``
- ``HandleReturnType``
- ``ServiceType``
- ``Operation``
- ``EndpointParameters``
- ``PathComponents``
- ``ScopedEndpointPathComponents``
- ``EndpointPathComponents``
- ``EndpointPathComponentsHTTP``
- ``AnyRelationshipEndpoint``
- ``RelationshipModelKnowledgeSource``
- ``ResponseType``
- ``WebServiceRoot``
- ``WebServiceComponent``
- ``Endpoint``
- ``Application``
- ``EndpointSource``
- ``AnyEndpointSource``
- ``Blackboards``
- `Context`
- ``CommunicationalPattern``
<!-- TODO: ``All`` -->
<!-- TODO: external KS: 
- `Logger` (`Logging`)
- `DefaultValueStore` (`ApodiniExtension`)
- `EndpointParametersById`  (`ApodiniExtension`)
-->
