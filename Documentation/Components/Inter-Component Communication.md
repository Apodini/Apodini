![document type: vision](https://apodini.github.io/resources/markdown-labels/document_type_vision.svg)

# Inter-Component Communication




## Summary

- The APIs described in this document are used to access, from within a handler's `handle()` function, the functionality provided by another handler
- The `InvocableHandler` protocol, which inherits from `IdentifiableHandler`, is used to denote `Handler`s which can be remotely invoked (ie, from within a `Handler.handle()` function)
- The `RemoteHandlerInvocationManager` type implements a helper object which is responsible for coordinating inter-component communication
- This helper object (you can think of this as a kind of mediator) has knowledge of the web service's structure and use that to determine how to realise interactions between handlers
- The API as currenly defined only supports invoking components which use the request-response communication pattern



## The `InvocableHandler` protocol

```swift
public protocol InvocableHandler: IdentifiableHandler where Response: Decodable {
    typealias ParametersStorageProtocol = InvocableHandlerParametersStorageProtocol
    associatedtype ParametersStorage: ParametersStorageProtocol = _EmptyParametersStorage<Self> where ParametersStorage.HandlerType == Self
}
```

An `InvocableHandler` is an `IdentifiableHandler` whose `Response` type conforms to `Decodable`, and which optionally defines a custom type for passing parameters to a remote invocation (see below for an explanation of how parameter passsing works).


## Defining and using invocable handlers

Simple example of a handler which accesses another handler's functionality.

```swift
struct RandomNumberGenerator: InvocableHandler {
    class HandlerIdentifier: ScopedHandlerIdentifier<RandomNumberGenerator> {
        static let main = HandlerIdentifier("main")
    }
    let handlerId = HandlerIdentifier.main
    
    @Parameter var lowerBound: Int
    @Parameter var upperBound: Int
    
    func handle() -> Int {
        Int.ramdom(in: lowerBound..<upperBound)
    }
}


struct Greeter: Handler {
    private var RHI = RemoteHandlerInvocationManager()
    
    @Parameter var name: String
    
    func handle() -> EventLoopFuture<String> {
        RHI.invoke(
            RandomNumberGenerator.self,
            identifiedBy: .main,
            parameters: [
                .init(\.$lowerBound, 0),
                .init(\.$upperBound, name.length)
            ]
        ).map { number in
            "Hello, \(name)! Your lucky number is \(number)."
        }
    }
}
```



## The Remote Invocation Manager


The invocation manager acts as a mediator overseeing all inter-handler interactions for a handler. Each handler which wants to interact with other handlers defines its own instance of the invocation manager.


### What's an interaction?

An interaction is an event where date are transferred between two handlers, and which was initiated within one of the two handler's `handle()` functions.

An interaction consists of the following parts:

- sender: the component type which initiated the interaction. This can be any `Handler`
- target: the component type the sender component is trying to invoke. This must be an `InvocableHandler`
- target identifier: the identifier of the target component
- parameters: An object which stores the values we want to pass to the target's `@Parameter`s

An interaction may be one-way (ie, the target doesn't send a response, or the response is discarded by the invocation manager), and the target does not necessarily know if it is being accessed by another handler (via the invocation manager) or by a "normal" client.

Broadly speaking, we differentiate between two kinds of interactions:

- Local (in-process) interactions
  - These are interactions where sender and target are running in the same process
  - In this case, the interaction is dispatched locally, ie the target endpoint's `handle()` function executed on the current event loop
- Remote (out-of-process) interactions
  - These are interactions where sender and target are running in different processed (potentially even on different machines and different networks)
  - Remote interactions are available when running a web service as a distributed system (ie, a system of distinct nodes, each of which implement a subset of the web service's exported endpoints)
  - In this case, the interaction is realised by finding the correct node within our distributed system, invoking the target component there, and returning the result back to the sender


### What does the invocation manager do?

The invocation manager is responsible for deciding whether the target component should be invoked locally or remotely, thus acting as a dispatcher. It is also responsible for realising the interaction.

The invocation manager has access to the full structure of the web service (eg via the `WebServiceModel` object) and the deployment structure (ie information about the number of processes running the web service, the endpoints implemented by each process, etc).
It uses these data to determine how to best dispatch individual invocations.
A handler's invocation manager is dynamically detected and provided this information, similarly to how `RequestInjectable`s are handled.

Based on this information, the invocation manager will:

1. locate the target handler
1. encapsulate the parameters (and other relevant data) into a `Request`
1. send that request to the target handler
1. wait for the target handler to finish and return a response
1. decode that response into the (statically known) target handler's response type
1. return the response object back to the sender

**Note:** Steps 2 through 4 might differ based on the deployed-to platform: whereas when running as a HTTP server on localhost we might simply send a HTTP request to the target (thus essentially emulating a client), on platforms like AWS Lambda it might be a better idea to use platform-provided APIs to directly invoke the target handler.

The `invoke` function returns an `EventLoopFuture`, since the invocation might be dispatched locally or remotely. For locally dispatched interactions, the returned future will always be succeeded, and contain the value returned by the invoked components' handle function.





## The remote-invocation API

```swift
func invoke<H: InvocableHandler>(
    _: H.Type,
    identifiedBy handlerId: H.HandlerIdentifier,
    parameters: <<parameters type>>
) -> EventLoopFuture<H.Response>
```
 

## Return values

The remote-invocation API returns an `EventLoopFuture`.  
Since invocations may be dispatched either locally or remotely, there is no guarantee as to whether an invocation is realised synchronous or asynchronous.

The returned object is the decoded response from the invoked handler. (This is the reason for the `where Response: Decodable` constraint on the `InvocableHandler` protocol.)



## Parameters


When invoking another handler, the values of the parameters expected by the invoked handler (ie, its `@Parameter` properties) must be specified by the caller.

Parameters for a remote invocation are 2-tuples consisting of a key path into the invoked handler (ie, a key path identifying the `@Parameter` the value belongs to) to the value.


There are two ways parameters can be specified:

1. An invocable handler can define what its remote-invocation parameters should be, and how they should be mapped to its `@Parameter` properties
2. An invocable handler can let Apodini take care of the mapping. (This is the default behaviour)

### 1. Using a dedicated `ParametersStorage` type nested in the invoked handler

The `InvocableHandler` protocol defines an (optional) associated type `ParametersStorage`.
A Handler can implement this type to provide a custom storage object for parameter values.

For handlers defining a parameter storage type, the remote-invocation API is as follows: 

```swift
func invoke<H: InvocableHandler>(
    _: H.Type,
    identifiedBy handlerId: H.HandlerIdentifier,
    parameters: H.ParametersStorage
) -> EventLoopFuture<H.Response>
```

The parameters storage type consists of two things:

- properties for the parameters which should be passed to the Handler
- a mapping from the `ParametersStorage` properties to the Handler's `@Parameter`s

The `mapping` static property is an array instructing the remote-invocation manager how the parameter storage's properties should be mapped to the Handler's `@Parameter`s.

If a Handler provides the `ParametersStorage` type, the remote-invocation API can only be used by passing an instance of this type. This gives the invoked handler full control over how its parameters should be passed. It also means that invalid remote-invocation parameters (eg: missing parameters, incorrect types, etc) can be caught at compile-time.

The benefit of the `ParametersStorage` approach is that the handler can exercise control over how the remote-invocation API should process its parameters.  
The downside is that the handler has to write boilerplate code, which needs to be kept in sync with its `@Parameter`s.

**Example**

```swift
struct RandomNumberGenerator: InvocableHandler {
    struct ParametersStorage: ParametersStorageProtocol {
        typealias HandlerType = RandomNumberGenerator
        
        let lowerBound: Int
        let upperBound: Int
        
        static let mapping: [MappingEntry] = [
            .init(from: \.lowerBound, to: \.$lowerBound),
            .init(from: \.upperBound, to: \.$upperBound)
        ]
    }
    
    class HandlerIdentifier: ScopedHandlerIdentifier<RandomNumberGenerator> {
        static let main = HandlerIdentifier("main")
    }
    let handlerId = HandlerIdentifier.main
    
    @Parameter var lowerBound: Int
    @Parameter var upperBound: Int
    
    func handle() -> Int {
        guard lowerBound <= upperBound else {
            return 0
        }
        return Int.random(in: lowerBound..<upperBound)
    }
}
```

### 2. Array-based parameter passing

If an `InvocableHandler` does not specify a `ParametersStorage` type, the remote-invocation API instead expects an array of keypath-value mappings:

```swift
func invoke<H: InvocableHandler>(
    _ handlerType: H.Type,
    identifiedBy handlerId: H.HandlerIdentifier,
    parameters: [CollectedParameter<H>] = []
) -> EventLoopFuture<H.Response> where H.ParametersStorage == _EmptyParametersStorage<H>
```

Where `CollectedParameter` is a struct storing:

- a key path to an `@Parameter` within an invocable handler
- the value which should be passed for this parameter


(`_EmptyParametersStorage ` is a non-initialisable type which a Handler can use to opt in to the array-based parameter passing. For `InvocableHandler`s which do not specify a `ParametersStorage` type, the parameter storage defaults to this type.)

Similar to how the `ParametersStorage` consisted of the parameter values alongside an array mapping the key path to a value (within the parameters storage) to the key path of its respective `@Parameter` (within the Handler), the `CollectedParameter`s expected by this function consist of the parameter value and the key path to the handler's `@Parameter`.

Entries for `@Parameter`s which define a default value may be omitted from the parameters array.  
If the parameters array contains multiple entries for the same `@Parameter` key path, the last one is used.  
Incomplete parameter lists (eg missing parameters) result in a run-time error.

The advantage of this parameter-passing approach is that the handler doesn't have to write boilerplate code.  
The downside, however, is the loss of compile-time well-formedness checking.



## A more complex example


```swift
import Foundation
import Apodini
import NIO



struct User: Codable {
    let name: String
    let email: String
    let age: Int
}


var users: [UUID: User] = [:]


struct CreateUser: InvocableHandler {
    class HandlerIdentifier: ScopedHandlerIdentifier<CreateUser> {
        static let main = HandlerIdentifier("main")
    }
    let handlerId = HandlerIdentifier.main
    
    @Parameter(.http(.body))
    var user: User
    
    func handle() -> UUID {
        let id = UUID()
        users[id] = user
        return id
    }
}


struct GetUser: InvocableHandler {
    class HandlerIdentifier: ScopedHandlerIdentifier<GetUser> {
        static let main = HandlerIdentifier("main")
    }
    let handlerId = HandlerIdentifier.main
    
    @Parameter var id: UUID
    
    func handle() -> User? {
        users[id]
    }
}


struct RandomStringGenerator: InvocableHandler {
    private static let alphanumerics = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    
    class HandlerIdentifier: ScopedHandlerIdentifier<RandomStringGenerator> {
        static let main = HandlerIdentifier("main")
    }
    let handlerId = HandlerIdentifier.main
    
    @Parameter var length: Int
    
    func handle() -> String {
        String((0..<length).compactMap { _ in Self.alphanumerics.randomElement() })
    }
}


struct RandomNumberGenerator: InvocableHandler {
    struct ParametersStorage: ParametersStorageProtocol {
        typealias HandlerType = RandomNumberGenerator
        let lowerBound: Int
        let upperBound: Int
        static let mapping: [MappingEntry] = [
            .init(from: \.lowerBound, to: \.$lowerBound),
            .init(from: \.upperBound, to: \.$upperBound)
        ]
    }
    
    class HandlerIdentifier: ScopedHandlerIdentifier<RandomNumberGenerator> {
        static let main = HandlerIdentifier("main")
    }
    let handlerId = HandlerIdentifier.main
    
    @Parameter var lowerBound: Int = 52
    @Parameter var upperBound: Int = 52
    
    func handle() -> Int {
        guard lowerBound <= upperBound else {
            return 0
        }
        return Int.random(in: lowerBound..<upperBound)
    }
}


struct Greeter: Handler {
    private var RHI = RemoteHandlerInvocationManager()
    
    @Parameter var name: String
    
    init(name: Parameter<String>) {
        _name = name
    }
    
    func handle() -> EventLoopFuture<String> {
        RHI.invoke(
            RandomNumberGenerator.self,
            identifiedBy: .main,
            parameters: .init(lowerBound: 0, upperBound: 12)
        ).flatMap { randomNumber -> EventLoopFuture<String> in
            RHI.invoke(
                RandomStringGenerator.self,
                identifiedBy: .main,
                parameters: [.init(\.$length, randomNumber)]
            )
        }.flatMap { randomString -> EventLoopFuture<UUID> in
            RHI.invoke(
                CreateUser.self,
                identifiedBy: .main,
                parameters: [.init(\.$user, User(name: name, email: "\(randomString)@gmail", age: 22))]
            )
        }.flatMap { userId -> EventLoopFuture<User?> in
            RHI.invoke(
                GetUser.self,
                identifiedBy: .main,
                parameters: [.init(\.$id, userId)]
            )
        }.map { user -> String in
            "Hello, \(name). Your user account is \(user)"
        }
    }
}


struct WebService: Apodini.WebService {
    @PathParameter var name: String
    
    var content: some Component {
        Text("welcome at the root level")
        Group("greet", $name) {
            Greeter(name: $name)
        }
        Group("random") {
            Group("int") {
                RandomNumberGenerator()
            }
            Group("string") {
                RandomStringGenerator()
            }
        }
        Group("api") {
            Group("user") {
                CreateUser().operation(.create)
                GetUser().operation(.read)
            }
        }
    }
}
```

