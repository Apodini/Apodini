![documentation](https://apodini.github.io/resources/markdown-labels/document_type_documentation.svg)

# Protocol Buffers

This file describes how the gRPC interface exporter and the protocol buffer IDL exporter are exporting the web service described in Apodini's DSL.

Protocol buffers are Google's language-neutral, platform-neutral, extensible mechanism for serializing structured data. [Source](https://developers.google.com/protocol-buffers/)

When we use **gRPC** or **GRPC**, we mean that this part of the program is responsible for the communication, i.e., remote procedure calls.
When we use **protocol buffers** or **Protobuffer**, we mean that this part of the program is responsible to work with Google's IDL.

## Exporters

The `Apodini.ProtobufferInterfaceExporter` exports a protocol buffer declaration of your `Apodini.WebService` in accordance to Google's [proto3 Language Guide](https://developers.google.com/protocol-buffers/docs/proto3).
A `.proto` declaration is available at `apodini/proto`.

The `Apodini.GRPCInterfaceExporter` exports endpoints for gRPC clients.
The `.proto` declaration shall be used to create a gRPC client that can communicate with your `Apodini.WebService` without any more work.

## Translation

We will look into some examples of how `Apodini.ProtobufferInterfaceExporter` translates `Apodini.Handler`s into protocol buffer `Service`s and `Message`s.

The following example results in a service with name `V1GreetService` and a single RPC method called `greeter`:

```swift
var content: some Component {
    Group("greet") {
        Greeter()
    }
}
```
becomes
```proto
service V1GreetService {
    rpc greeter(/**/) returns (/**/);
}
```

### Parameters

All `@Parameters` are dealt with in the same way for gRPC.
In gRPC the only way a handler can receive parameters is via the message payload.
This means all parameters will be decoded from the message payload, no matter of which type (`.body`, `.path`, ...) a `@Parameter` is.

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

### Field Numbers

Protobuffers use unique numbers / field tags to identify each field of a message.
The exporters will enumerate all parameters in the order they are placed in the source file by default.

```swift
struct Greeter: Handler {
   @Parameter
   var name: String

   @Parameter
   var isFormal: Bool

   func handle() -> String {
       // ...
   } 
}
```
becomes
```proto
message GreeterMessage {
    string name = 1;
    bool isFormal = 2;
}
```

The same holds for non-primitive parameters with nested data structures.

## Options

### Custom Service Names

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

### Custom Method Names

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

### Custom Field Numbers

Apodini allows you to manually define field tags.
For parameters of Components, this can be done using the `gRPCParameterOptions.fieldTag`:

```swift
struct Greeter: Component {
   @Parameter("name", .gRPC(.fieldTag(2))
   var name: String
   // ...
}
```

For non-primitive parameters and nested data structures, this can be done using the `CodingKey`s of `Codable` structs.
Please refer to the documentation of the ProtobufferCoding module [here](<./../../Sources/ProtobufferCoding/README.md>).

### Mixing automatic inference and custom field numbers

You can also only add manually defined field numbers to some of the parameters, and let Apodini infer the field numbers for the others. 
Apodini will enumerate all parameters in the order they are place in the source file and override the unique numbers with the manually annotated field tag.

```swift
struct Greeter: Handler {
   @Parameter
   var firstName: String

   // The infered unique number would be 2,
   // but the annotation overrides it with 5.
   @Parameter("lastName", .gRPC(.fieldTag(5))
   var lastName: String 

   @Parameter
   var isFormal: Bool

   func handle() -> String {
       // ...
   } 
}
```
becomes
```proto
message GreeterMessage {
    string firstName = 1;
    string lastName = 5;
    bool isFormal = 3;
}
```
