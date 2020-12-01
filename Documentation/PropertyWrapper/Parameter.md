# `@Parameter`

The `@Parameter` property wrapper can be used to express input in different ways. 
The internal name of the `@Parameter` and can be different to the external representation of the component by passing a string into the `@Parameter` property wrapper as first - optional - argument.
```swift
struct ExampleComponent: Component {
    @Parameter var name: String
    @Parameter("repeat") var times: Int

    // ...
}
```

## Inference

Apodini is designed so that different exporters for different protocols can infer as much information as possible about Parameters. 
Here's a simple overview of how this inference should work.

### Parameters Expressing Request Content

Non primitive types defined by the user that conform to `Codable` and are not [`LosslessStringConvertible`](https://developer.apple.com/documentation/swift/losslessstringconvertible) are automatically considered to be a request content for all protocols and types of middleware that are applicable to contain a request content such as an HTTP body. If there are multiple non primitive types marked with `@Parameter` the elements should be encoded in a wrapper enclosure.

### Single `@Parameter` for Request Content

The following example showcases a simple component with one `@Property` wrapper around a non primitive type:
```swift
struct Bird: Codable {
    var name: String
    var age: Int
}

struct ExampleComponent: Component {
    @Parameter var bird: Bird

    // ...
}
```

*JSON Based APIs*

This `Component` can be exported as in a JSON based API by sending a POST request with the following JSON in the body of the HTTP request:
```json
{
    "name": "Swift",
    "age": 42
}
```

*gRPC*

```protobuf
service Example {
    rpc Example (Bird) returns (/*...*/) {}
}

message Bird {
    string name = 1;
    int32 age = 2;
}
``` 

*GraphQL*

```graphql
type Bird {
  name: String!
  age: Int!
}

type Query {
    example(bird: Bird): /*...*/
}
```

*WebSocket*

Exposing the `Component` on a web socket interface requires the client to send the following message encoded as JSON:
```json
{
    "type": "Example",
    "parameters": {
        "name": "Swift",
        "age": 42
    }
}
```

### Multiple `@Parameter`s for Request Content

The following example showcases a component with multiple `@Parameter` property wrappers around a non primitive type:
```swift
struct Bird: Codable {
    var name: String
    var age: Int
}

struct Plant: Codable {
    var name: String
    var height: Int
}

struct ExampleComponent: Component {
    @Parameter var bird: Bird
    @Parameter var plant: Plant

    // ...
}
```

*JSON Based APIs*

This `Component` can be exported as in a JSON based API by sending a POST request with the following JSON in the body of the HTTP request:
```json
{
    "bird": {
        "name": "Swift",
        "age": 42
    },
    "plant": {
        "name": "Rose",
        "height": 10
    }
}
```

*gRPC*

```protobuf
service Example {
    rpc Example (SearchRequest) returns (/*...*/) {}
}

message SearchRequest {
    message Bird {
        string name = 1;
        int32 age = 2;
    }

    message Plant {
        string name = 1;
        int32 height = 2;
    }

    Bird bird = 1;
    Plant plant = 2;
}
``` 

*GraphQL*

```graphql
type Bird {
  name: String!
  age: Int!
}

type Plant {
  name: String!
  height: Int!
}

type Query {
    example(bird: Bird, plant: Plant): /*...*/
}
```

*WebSocket*

Exposing the `Component` on a web socket interface requires the client to send the following message encoded as JSON:
```json
{
    "type": "Example",
    "parameters": {
        "bird": {
            "name": "Swift",
            "age": 42
        },
        "plant": {
            "name": "Rose",
            "height": 10
        }
    }
}
```

## Lightweight Parameters

Some middleware types and protocols can expose parameters as lightweight parameters that can be part of a URI path such as query parameters found in the URI of RESTful and OpenAPI based interfaces. Apodini automatically exposes primitive types as lightweight parameters that conform to [`LosslessStringConvertible`](https://developer.apple.com/documentation/swift/losslessstringconvertible). Complex types such as custom types conforming to `Codable` can not be exposed using lightweight parameters. 

### Simple Lightweight `@Parameter`s Example

```swift
struct Bird: Codable {
    var name: String
    var age: Int
}

struct ExampleComponent: Component {
    // Is exposed as a content of a request
    @Parameter var bird: Bird
    // Is exposed as a content of a request, indicates how often the bird should be returned in the response. Has a default value.
    @Parameter("times", .http(.body)) var repeat: Int = 1
    // Is exposed as a `lightweight` parameter for interfaces that support it. Also has a default value of true and indicates if emojis should be used in the response.
    @Parameter var emoji: Bool = true

    // ...
}
```

*JSON Based APIs*

This `Component` can be exported as in a JSON based API by sending a POST request to `.../example?emoji=false` or `.../example` to assume the default value. The request includes the the following JSON in the body of the HTTP request:
```json
{
    "bird": {
        "name": "Swift",
        "age": 42
    },
    "times": 1
}
```
or to assume the default value for `times`:
```json
{
    "bird": {
        "name": "Swift",
        "age": 42
    }
}
```

*gRPC*

```protobuf
service Example {
    rpc Example (ExampleRequest) returns (/*...*/) {}
}

message ExampleRequest {
    message Bird {
        string name = 1;
        int32 age = 2;
    }

    Bird bird = 1;
    int32 times = 2;
    bool emoji = 3;
}
``` 

*GraphQL*

```graphql
type Bird {
  name: String!
  age: Int!
}

type Query {
    example(bird: Bird, times: Int = 1, emoji: Bool = true): /*...*/
}
```

*WebSocket*

Exposing the `Component` on a web socket interface requires the client to send the following message encoded as JSON:
```json
{
    "type": "Example",
    "parameters": {
        "bird": {
            "name": "Swift",
            "age": 42
        },
        "times": 42,
        "emoji": false
    }
}
```

## Path Parameters

Some middleware types and protocols can expose parameters as part of the endpoint defining characteristics. E.g. RESTful and OpenAPI based APIs use the URI path to define endpoints including variables such as `/birds/BIRD_ID` to identify the requested `Bird` by its identifier `BIRD_ID`.
We can infer that a specific parameter is part of this path for example: if it contains the word ID in the name and is at the start of the Component. 

### Defining a Parameter

```swift
struct Bird: Codable, Identifiable {
    var id: Int
    var name: String
    var age: Int
}

struct ExampleComponent: Component {
    @Parameter var birdID: Bird.ID

    // ...
}

struct TestWebService: WebService {
    var content: some Component {
        Group("api", "birds") {
            ExampleComponent()
        }
    }
}

TestWebService.main()
```

*JSON Based APIs*

If the `Component` is registered at `/api/birds` the client can request a bird with the identifier `42` by sending a HTTP GET request to `/api/birds/42/`.

*gRPC*

```protobuf
service Birds {
    rpc Example (BirdID) returns (...) {}
}

message BirdID {
    int32 id = 1;
}
``` 

*GraphQL*

```graphql
type Query {
    example(birdID: Int): ...
}
```

*WebSocket*

Exposing the `Component` on a web socket interface requires the client to send the following message encoded as JSON:
```json
{
    "type": "Example",
    "parameters": {
        "birdID": 42
    }
}
```

### Defining a Parameter  Defining an Endpoint outside an Endpoint

The `@Parameter` property used as a path parameter can also be defined outside the component as part of a Group that contains the `Component`.

```swift
struct Bird: Identifiable {
    var id: Int
    var name: String
    var age: Int
}

struct ExampleBirdComponent: Component {
    // As this was passed in from the outside this is automatically used as a path parameter
    @Parameter var birdID: Bird.ID

    // ...
}

struct ExampleNestComponent: Component {
    // As this was passed in from the outside this is automatically used as a path parameter
    @Parameter var birdID: Bird.ID
    // Exposed as a lightweight parameter
    @Parameter var nestName: String?

    // ...
}

struct TestWebService: WebService {
    @Parameter var birdID: Bird.ID

    var content: some Component {
        Group("api", "birds", birdID) {
            ExampleBirdComponent(birdID: $birdID)
            Group("nests") { 
                ExampleNestComponent(birdID: $birdID)
            }
        }
    }
}

TestWebService.main()
```

## Explicit Options

Middlewares are supposed to infer the best possible form of representing parameters.
However, some middleware types and protocols may want to provide some additional customization, so that developers may forego the inference, and provide a strategy explicitely.
The values of these options can be defined by the exporters, and each exporter can read for the options specific to itself. For example: for HTTP JSON Based APIs, the exporter might want to allow the user to specify if a parameter is supposed to be retrieved from:
- URI Path
- HTTP Body
- Query Params
- etc.

### Defining Options

The exporter can define it's own options, by defining the type of the options, the key to identify the option and a helper to make it work seamlessly with the Parameter Property Wrapper:

```swift
// Define a Type
public enum HTTPParameterMode: PropertyOption {
    case body
    case path
    case query
}

// Define a Key
extension PropertyOptionKey where Property == ParameterOptionNameSpace, Option == HTTPParameterMode {
    static let http = PropertyOptionKey<ParameterOptionNameSpace, HTTPParameterMode>()
}

// Add helper to register it to a Parameter Property Wrapper
extension AnyPropertyOption where Property == ParameterOptionNameSpace {
    public static func http(_ mode: HTTPParameterMode) -> AnyPropertyOption<ParameterOptionNameSpace> {
        return AnyPropertyOption(key: .http, value: mode)
    }
}
```

With the new definition of `HTTPParameterMode` the developer may now define explicitely to the exporter how they would like their parameters to be exported:

```swift
struct ExampleComponent: Component {
    @Parameter(.http(.body)) 
    var bird: Bird
    
    // Can define different handling for different exporters
    @Parameter(.http(.path), .webSocket(.constant))
    var id: UUID = true

    // ...
}
```

This has the additional benefit of making the options for each exporter explicit and clear in code, and therefore more readable, while at the same time keeping the exporters and the DSL decoupled.

### Reading the Options

Each exporter then can read the use of it's options in the property by using the key:

```swift
extension Parameter {
    internal func httpMode() -> HTTPParameterMode {
        if let mode = option(\.http) {
            return mode
        }
        
        // infer mode based on other heuristics
    }
}
```
