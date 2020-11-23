# Apodini Component Types

This document provides an overview of different compoenent types that are part of Apodini.

## Component Types

 1. **Request-Response Component**: A single request is answered by a single response (`Request -> Response`)
 2. **[Service-Side Stream Component](/ComponentTypes/ServiceSideStream.md)**: A single response is answered by multiple responses that are terminated by the web service (`Request -> [Response]`) 
 3. **[Client-Side Stream Component](/ComponentTypes/ClientSideStream.md)**: Multiple requests by a client that are terminated by a single response from the web service (`[Request] -> Response`)
 4. **[Bidirectional Stream Component](/ComponentTypes/BidirectionalStream.md)**: An open communication channel where both parties can send messages at any time. The connection is terminated by either the client or web service (`[Request] -> [Response]`)
 
All request and response types could also be `Void` or `nil`. We consider `Request -> ()` or `[Request] -> ()` no separate components as this is achieved using an `Request -> Response` or `[Request] -> Response` component with a `Void` return type or returning `nil`.  
How a specific protocol or middleware handles `Void` or `nil` is up to the implementation of the specific exporter.

Components that are not request and response based are discussed in the [Component Type documentation](/ComponentTypes).
* [Service Side Streams](/ComponentTypes/ServiceSideStream.md)
* [Client Side Streams](/ComponentTypes/ClientSideStream.md)
* [Bidirectional Streams](/ComponentTypes/BidirectionalStream.md)

In addition Apodini also offers a way to send out unsolicited events that is sent to the client from the web service based on some event (`() -> Response`) without a request such as push notifications. Further details are described in the [Push Notifications documentation](AdditionalFunctionality/PushNotifications).


## Apodini `Component`s

Simple request-response `Component`s include `@Parameters` that are injected based on the request structure and include a `handle` method that returns the response that is computed by the `Component`.
The [`@Parameter`](/PropertyWrapper/Parameter.md), [`@Environment` and `@Request`](/PropertyWrapper/RequestAndEnvironment.md) property wrappers are explained in more detail in thier [respective documentation](/PropertyWrapper).

Request-response components can include more complicated logic such as async operations to save elements into a database. In addition to `Strings` or other primitive types, the handle function can also return `EventLoopFuture`s to indicate async tasks.

The following `Component` repeats the name passed in as a `@Parameter` as many times as described by the second `@Parameter`.

```swift
struct ExampleComponent: Component {
    @Parameter var name: String
    @Parameter var times: Int


    func handle() -> String {
        // Repeats the sentence "Hello \(name)!" as often as saved in the repeat parameter.
        (0...times)
            .map { _ in
                "Hello \(name)!"
            }
            .joined(separator: ", ")
    }
}
```

### JSON Based APIs

This `Component` can be exported as in a JSON based API by sending a GET request with no body to an emdpoint with the URL query parameters `name` and `repeat`, e.g.: `\parameter?name=Paul&repeat=42`.

### gRPC 

It could also be exposed as a gRPC method with the following service: 
```protobuf
service Example {
    rpc Example (ExampleRequest) returns (ExampleResponse) {}
}

message ExampleRequest {
    string name = 1;
    int32 times = 2;
}

message ExampleResponse {
    string response = 1;
}
``` 

### GraphQL

The same component can also be exposed as part of a GraphQL schema:
```graphql
type Query {
  example(name: String, times: Int): String
}
```

### WebSocket

Exposing the `Componet` on a web socket interface requires the client to send the following message encoded as JSON:
```json
{
    "type": "Example",
    "parameters": {
         "name": "Paul",
         "times": 42
    }
}
```
and returns a response similiar to:
```json
{
    "type": "Example",
    "response": "Hello Paul!, Hello Paul! ..."
}
```
