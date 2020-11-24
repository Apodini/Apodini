# `@Parameter`

The `@Parameter` property wrapper can be used to express input in different ways: 
* **Request Content**: Parameters can be part of the requests send to the web service such as the HTTP body or request content of an other protocol.
* **Lightweight Parameter**: Some middleware types and protocols can expose parameters as lightweight parameters that can be part of a URI path such as query parameterst found in the URI of RESTful and OpenAPI based web APIs.
* **Path Parameters**: Parameters can also be used to define the endpoint such as the URI path of the middleware types and protocols that support URI based multiplexing of requests.

The internal name of the `@Parameter` and can be different to the external representation of the component by passing a string to the `@Parameter` wrapper and is the first argument that can be optionally passed into the `@Parameter` property wrapper.
```swift
struct ExampleComponent: Component {
    @Parameter var name: String
    @Parameter("repeat") var times: Int

    // ...
}
```

## Parameters Expressing Request Content

Non primitive types defined by the user that conform to `Codable` and are not [`LosslessStringConvertible`](https://developer.apple.com/documentation/swift/losslessstringconvertible) are automatically considered to be a request content for all protocols and types of middleware that are applicable to contain a request content such as an HTTP body. If there are multiple non primative types marked with `@Parameter` the elements should be encoded in a wrapper enclosure.

### Single `@Parameter` for Request Content

The folowing example showcases a simpe component with one `@Property` wrapper around a non primative type:
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

Exposing the `Componet` on a web socket interface requires the client to send the following message encoded as JSON:
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

The folowing example showcases a component with multipe `@Parameter` property wrappers around a non primative types:
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

Some middleware types and protocols can expose parameters as lightweight parameters that can be part of a URI path such as query parameters found in the URI of RESTful and OpenAPI based interfaces. Apodini automatically exposes primative types as lightweight parameters that conform to [`LosslessStringConvertible`](https://developer.apple.com/documentation/swift/losslessstringconvertible). Complex types such as cunstom types conforming to Codable can not be exposed using lightweight parameters. A lightweight parameter is defined the same way a normal parameter can be defined. The developer using Apodini can force a specific behaviour by passing in an enum value into the property warpper initializer, e.g. `@Parameter(.lightweight)`. Possible values are:
* `.automatic`: Apodini infers the type of parameter based on the type information of the wrapped propety. This is the default behaviour of an `@Parameter` property wrapper.
* `.lightweight`: This option can only be used of the type wrapped conforms to [`LosslessStringConvertible`](https://developer.apple.com/documentation/swift/losslessstringconvertible). The parameter is exposed as a lightweight parameter if supported by the middleware or protocol.
* `.content`: The parameter is exposed using the content of the request send to the web service. If there are multiple `@Parameter` property wrappers annotated with `@Parameter(.content)` the same strategy as if there are multiple `@Parameter` property wrappers with types not conforming to [`LosslessStringConvertible`](https://developer.apple.com/documentation/swift/losslessstringconvertible) is applied.

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
    @Parameter("times", .content) var repeat: Int = 1
    // Is exposed as a `lightweight` parameter for interfaces that support it. Also has a default value of true and indicates if emojis should be used in the response.
    @Parameter var emoji: Bool = true

    // ...
}
```

*JSON Based APIs*

This `Component` can be exported as in a JSON based API by sending a POST request to `.../example?emoji=false` or `.../example` to assume the defauilt value. The request includes the the following JSON in the body of the HTTP request:
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

Some middleware types and protocols can expose parameters as part of the endpoint defining charactersistics. E.g. RESTful and OpenAPI based APIs use the URI path to define endpoints using variables such as `/birds/BIRD_ID` to identify the `Bird` the request is target at using the `BIRD_ID`.
The `@Parameter` property wraper exposes the option to explictly defining a parameter as defining an andpoint using the `.path` option.

### Defining a Parameter  Defining an Endpoint in an Endpoint

```swift
struct Bird: Codable, Identifiable {
    var id: Int
    var name: String
    var age: Int
}

struct ExampleComponent: Component {
    @Parameter(.path) var birdID: Bird.ID

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

The `@Parameter` property used as a path parameter can also be defined outside the component as part of a Group that contains the `Compoent`.

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
