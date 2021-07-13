# DSL Components

Apodini's central building block.

Components are the Apodini DSL's central building block.

Web services are defined as tree-like composition of `Component`s.


A component can either provide further components, or provide some functionality which can be invoked by the user.
The differentiation between these two main kinds of DSL constructs is expressed via the following types:

- `Component`: a component which does not expose any user-facing functionality, but provides further content (via its `content` property)
- `Handler`: a component which exposes user-facing functionality (ie, a component which can handle and respond to requests).



**Example** A simple web service

```swift
struct RandomNumberProvider: Handler {
    func handle() -> Int {
        return Int.random()
    }
}

struct WebService: Apodini.WebService {
    var content: some Component {
        Text("hello there")
        Group("random") {
            RandomNumberProvider()
        }
    }
}
```

This example defines a simple web service consisting of a greeting message and a random number generator.



### Components

The `Component` protocol defines a type which provides further content:

```swift
protocol Component {
    associatedtype Content: Component
    
    @ComponentBuilder
    var content: Content { get }
}
```




### Handlers

The `Handler` protocol defines a `Component` which can respond to user requests:

```swift
protocol Handler: Component {
    associatedtype Response: Encodable
    
    func handle() -> Response
}
```

When a request reaches the endpoint at which the Handler is placed, its `handle` function will be invoked to respond to the request.

Handlers can use the [`@Parameter`](https://github.com/Apodini/Apodini/blob/develop/Documentation/PropertyWrapper/Parameter.md) property wrapper to access request-related data.

Since `Handler` inherits from the `Component` protocol, a handler may also implement a the `content` property to provide further components. By default, i.e. if the `content` property is not implemented, handlers do not provide any further content.

A handler can, based on the properties it defines, make use of one of several [communicational patterns](https://github.com/Apodini/Apodini/tree/develop/Documentation/Communicational%20Patterns).



### Identifying Handlers


The `IdentifiableHandler` protocol is used to define a uniquely identifiable `Handler`.
This is important for being able to differentiate between and reference individual instances of a component within the DSL.

```swift
protocol IdentifiableHandler: Handler {
    associatedtype HandlerIdentifier: AnyHandlerIdentifier
    var handlerId: HandlerIdentifier { get }
}
```

A handler's identifier must be a static, non-random, and unique string value which must persist across multiple compilations and executions of the program (as long as the program remains unchanged). The reason for this requirement is that Apodini needs to be able to identify and find the same handler across multiple instances of a web service.

There are two ways an `IdentifiableHandler`s identifier can be provided:

- `AnyHandlerIdentifier`. A type-erased identifier type, which simply wraps around a string.
- `ScopedHandlerIdentifier<H>`. A type-preserving identifier type which is scoped to a single `Handler` type.


**Example** Using `IdentifiableHandler` to resolve ambiguity between handlers

```swift
struct PostTweet: IdentifiableHandler {
  enum Behaviour {
    case regular, legacy
  }

  class HandlerIdentifier: ScopedHandlerIdentifier<PostTweet> {
    static let normal = HandlerIdentifier("normal")
    static let legacy = HandlerIdentifier("legacy")
  }

  let maxLength: Int
  let handlerId: HandlerIdentifier

  init(_ behaviour: Behaviour) {
    switch behaviour {
    case .regular:
      maxLength = 280
      handlerId = .normal
    case .legacy:
      maxLength = 140
      handlerId = .legacy
    }
  }

  func handle() -> Response {
    // ....
  }
}
```

Using `ScopedEndpointIdentifier` instead of `AnyHanderIdentifier` allows us to reject identifiers for other handler types.  
For example, if you have some other handler which defines the identifier `.foo`, you can't pass that other handler's `.foo` identifier when trying to reference a `PostTweet` instance, since it's an identifier for a different Handler type.

## Topics

### <!--@START_MENU_TOKEN@-->Group<!--@END_MENU_TOKEN@-->

- <!--@START_MENU_TOKEN@-->``Symbol``<!--@END_MENU_TOKEN@-->
