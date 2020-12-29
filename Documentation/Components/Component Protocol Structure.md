# Documentation: `Component` protocol structure


- Author: Lukas Kollmer
- Date: 2020-12-16
- Draft Implementation: [documentation/add-component-protocols-proposal][branch_url]


<details>
<summary>(Initial reasoning for the `Component` rewrite)</summary>

## Summary

- We should replace `Component` with a collection of several, more fine-grained protocols, which match more closely to the different [kinds of components](https://github.com/Apodini/Apodini/tree/develop/Documentation/Communicational%20Patterns/3.%20Pattern%20Implementation) we eventually want to support
- Instead of a single protocol, there should be a hierarchical structure of several protocols, similar to [how Swift models numeric types](https://files.lukaskollmer.de/embed/swift_numerics.png)
- When defining a concrete component, the user would make that component conform to the protocol matching the component's intended use-case
- We use the type system to ensure that components can only appear in places in the DSL where they actually make sense
- For example, the leaves in the DSL's syntax tree must always be endpoints (ie components w/ a `handle()` function)
- If possible, an ill-formed `WebService` shouldn't compile in the first place




## The status quo

Currently, the `Component` protocol serves as a one-size-fits-all solution for all "things which can appear in the DSL".

Why is this bad? Let's have a look at `Component`'s [current definition](https://github.com/Apodini/Apodini/blob/83a513327ff094cc9666a0e51a2f4cda67fd8f91/Sources/Apodini/Components/Component.swift)

```swift
protocol Component {
    associatedtype Content: Component = Never
    associatedtype Result: ResponseEncodable = Never
    
    @ComponentBuilder
    var content: Content { get }
    
    func handle() -> Response
}
```


- `content`: used to provide further DSL components
- `handle()`: used to specify how the component should respond to incoming requests

The issue here is that these two members are, in effect, mutually exclusive: if a component implements both `content` and `handle()`, we currently ignore its `handle()` function and only look at `content`.




If we think of the `WebService`, as defined via the DSL, as a tree data structure, we can come up with the following mapping:

- root node: the entry point into the `WebService`
- internal nodes (ie non-leaf nodes): intermediate components used for grouping, which eventually lead to one or more endpoints
- leaves: endpoints, which expose functionality via their `handle()` function


The issue with the current definition of the `Component` protocol is that it is trying to cover all of these three cases at the same time, with the same interface.


One of the additional side effects of switching to a more fine-grained protocol structure is that we can use the type system to express some of the requirements a web service must satisfy. For example, we should be able to define the protocols/types/builder in a way that ill-formed web services will cause a compile-time error.




### Issues caused by the current implementation


#### Invalid Components

Both of these components currently compile, despite not being valid components:

```swift
// empty component which implements neither `content` nor `handle()`
struct A: Component {}

// component which implements both `content` and `handle()`
struct B: Component {
    var content: some Component { ... }
    func handle() -> Response { ... }
}
```

More generally speaking, fully half of the four possible combinations of conforming to the `Component` protocol will result in invalid components:

<!--- Implement neither `content` nor `handle()`: ❌
- Implement only `content`: ✅
- Implement only `handle()`: ✅
- Implement both `content` and `handle()`: ❌-->


|            | `content` | `handle()` | component valid? |
| :--------- | :-------: | :--------: | :--------------: |
| implements |  no       | no         | ❌       |
| implements |  yes      | no         | ✅               |
| implements |  no       | yes        | ✅               |
| implements |  yes      | yes        | ❌               |




#### Type inference

Because the current implementation defaults both `Content` and `Response` to `Never`, you can end up in situations where a seemingly properly defined component is in fact ill-formed.


Consider the following example:

```swift
struct User: Codable {
    let id: ID
    let name: String
    let age: Int
}

struct GetUser: Component {
    @Parameter("userId")
    var userId: User.ID
    
    func handle() -> User {
        // ...
    }
}
```


This component, despite compiling just fine and not causing a single warning or error, will never work as intended.  
The reason for this is that `User` doesn't conform to `ResponseEncodable`, meaning that swiftc will resolve `GetUser.Response` to `Never` (the default value), which will cause Apodini to invoke the `handle` function implemented in the `Response == Never` protocol extension.  
The result is that, when a request is sent to the component's endpoint, it will crash at runtime.


**Generally speaking, if we can use the type system to statically detect and reject ill-formed programs, instead of having to perform these checks at runtime, we should always do so.**


### How does the rewrite affect the current implementation?

Switching to this new structure required surprisingly few changes.
In most cases it was sufficient to replace `Component` with `Handler`, since the semantic model builder already operates only on endpoint nodes, and never on non-endpoint nodes. All tests still pass.

- `Text` is now a `Handler`
- `EmptyComponent` is removed, since user-exposed empty components were invalid DSL components to begin with.  
  (It still is possible to define a noop component, by typealiasing `Content` or `Response` to `Never`.)
- Some tests needed to be updated (since a component's nested handlers can't be accessed via `component.content as? SomeHandlerType`)
- `AnyComponent` is replaced by `AnyEndpointNode` and `AnyEndpointProvidingNode`
- Neither `content` nor `handle()` have a default implementation anymore.
  You have to provide an implementation for your components to compile.
  (The exception here is if you manually add a `typealias {Content|Response} = Never`, in which case we do still provide a default implementation. The idea is that, if you want a component to be unusable, and crash if ever accessed, you have to explicitly specify this.)
  
  
### Alternatives considered

- Simply keep the current implementation and change nothing
- Remove the `= Never` defaults from the `Content` and `Response` associated types
    - This would solve the issue of empty components being valid
    - It would also solve the issue of a user-defined `handle()` function not being picked up properly by the compiler
    - It would, however, not solve the issue of `content` and `handle()` being mutually exclusive


</details>



## Defining Components

### Protocol structure

```swift
protocol Component {
    associatedtype Content: Component
    
    @ComponentBuilder
    var content: Content { get }
}


protocol Handler: Component {
    associatedtype Response: Encodable
    
    func handle() -> Response
}


protocol IdentifiableHandler: Handler {
    associatedtype EndpointIdentifier: AnyEndpointIdentifier
    
    var endpointId: EndpointIdentifier { get }
}
```

- `Component`s are nodes which sit above the leaves.  
  They cannot provide any functionality of their own, but they must eventually lead to one or more `Handler`s.
- `Handler`s are nodes which expose some functionality to the client.  
  All leaves in the `WebService` must be `Handler`s.
- `IdentifiableHandler`s are handlers which can be uniquely identified within the DSL.






### Benefits this more fine-grained protocol structure:

**Type Safety**

With the current implementation, we'd need to rely heavily on runtime checks to validate the DSL structure and rejct invalid web services.

By using protocols to define some of these component concepts, we can make use of the type system to enforce these requirements.

This directly benefits both the user (ie the person implementing a web service), and us:

- The user will, in some cases, get compile-time errors when trying to compile incorrectly implemnented components, or ill-formed DSL constructs
- We can, when dealing with DSL nodes, always know for a fact their specific type and functionalities and won't have to do any dynamic or runtime-metadata based checks to determine that information







## Documentation: Identifying handlers

Being able to reference an individual instance of a `Handler` within the DSL is required for inter-component communication.
Since a web service might contain multiple instances of a `Handler` type, we cannot rely on the static type alone.

The `IdentifiableHandler` protocol denotes `Handler` types where the type's individual instances can be uniquely identified.
A handler's identifier must be the same across multiple compilations and executions of the program, as long as the structure of the web service remains unchanged.

All `Handler`s get a default identifier, which can optionally be overwritten by the user, by conforming to the `IdentifiableHandler` protocol.

There are two ways to identify an `IdentifiableHandler`:
- `AnyEndpointIdentifier`: identifies a handler of an unknown type
- `ScopedEndpointIdentifier`: identifies a handler of a known specific type


Example: using endpoint identifiers to resolve ambiguity between handlers

```swift
struct PostTweet: IdentifiableHandler {
  enum Behaviour {
    case regular, legacy
  }

  class EndpointIdentifier: ScopedEndpointIdentifier<PostTweet> {
    static let normal = EndpointIdentifier("normal")
    static let legacy = EndpointIdentifier("legacy")
  }

  let maxLength: Int
  let endpointId: EndpointIdentifier

  init(_ behaviour: Behaviour) {
    switch behaviour {
    case .regular:
      maxLength = 280
      endpointId = .normal
    case .legacy:
      maxLength = 140
      endpointId = .legacy
    }
  }

  func handle() -> Response {
    // ....
  }
}
```


Using a `ScopedEndpointIdentifier` instead of `AnyEndpointIdentifier` allows us to reject identifiers for other handler types.
For example, if you have another component with the identifier `.foo`, you can't pass `.foo` when trying to reference a `PostTweet` instance, since it's an identifier for a different Handler type.




[branch_url]: https://github.com/Apodini/Apodini/tree/documentation/add-component-protocols-proposal
