![document type: vision](https://apodini.github.io/resources/markdown-labels/document_type_vision.svg)

# Protocol Buffers

Protocol buffers are Google's language-neutral, platform-neutral, extensible mechanism for serializing structured data. [Source](https://developers.google.com/protocol-buffers/)

When we use **gRPC**, we mean that this part of the program is responsible for the communication, i.e., remote procedure calls.
When we use **protocol buffers** or **Protobuffer**, we mean that this part of the program is responsible to work with Google's IDL.

## Exporters

The `Apodini.ProtobufferInterfaceExporter` exports a protocol buffer declaration of your `Apodini.WebService` in accordance to Google's [proto3 Language Guide](https://developers.google.com/protocol-buffers/docs/proto3).
The declaration `webservice.proto` is available at `apodini/webservice.proto`.

The `Apodini.GRPCInterfaceExporter` exports endpoints for gRPC clients.
The `webservice.proto` declaration shall be used to create a gRPC client that can communicate with your `Apodini.WebService` without any more work.

## Translation

We will look into some examples of how `Apodini.ProtobufferInterfaceExporter` translates `Apodini.Handler`s into protocol buffer `Service`s and `Message`s.

The following example results in a service with name `V1Greeter` and a single RPC method called `greeter`:

```swift
var content: some Component {
    Group("greet") {
        Greeter()
    }
}
```
becomes
```proto
service V1GreeterService {
    rpc greeter(/**/) returns (/**/);
}
```

### Parameters

All `@Parameters` are dealt with in the same way for gRPC.
In gRPC the only way a handler can receive parameters is via the message payload.
This means all parameters will be decoded from the message payload, no matter of which type (`.body`, `.path`, ...) a `@Parameter` is .

```swift
struct Greeter: Handler {
    @Parameter var name: String

    func handle() -> String {
        "Hello \(name)"
    }
}
```
becomes
```proto
message GreeterMessage {
    string name = 1;
}
```

## Options

### Custom service names

Service names are derived from the `Apodini.Component` tree by default.
All path components leading to a handler will be concatenated to a unique name.

The service name can be explicitly set by using the `.serviceName` modifier.

```swift
var content: some Component {
    Group("greet") {
        Greeter()
        Text("Hallo Welt")
    }
    .serviceName("GreetService")
}
```
becomes
```proto
service GreetService {
    rpc greeter(/**/) returns (/**/);
    rpc text(/**/) returns (/**/);
}
```

The `Apodini.Component` tree needs to be flattend to be representable as a gRPC service.
Only the `.serviceName` modifier applied at the deepest level of the tree will be considered.
Thus, the following example would result in the same output as shown above:

```swift
var content: some Component {
    Group("messaging") {
        Group("greet") {
            Greeter()
            Text("Hallo Welt")
        }
        .serviceName("GreetService")
    }
    .serviceName("MessagingService")
}
```

### Custom method names

`Apodini.Handler`s will be exported as methods, with the name of the handler type as the method name.
The names of methods can also be explicitly set by using the `.methodName` modifier.

```swift
var content: some Component {
    Group("greet") {
        Greeter()
            .methodName("greetByName")
        Text("Hallo Welt")
    }
    .serviceName("GreetService")
}
```
becomes
```proto
service GreetService {
    rpc greetByName(/**/) returns (/**/);
    rpc text(/**/) returns (/**/);
}
```
