# GRPC Exporter of Apodini

This file describes how the gRPC interface exporter and the Protobuffer IDL exporter are exporting the API described in Apodini DSL.

## Service and method names
By default, service names are derived from the Apodini Component-Tree. This means, all PathComponents leading to a handler will be concatenated to a long, unique name. 
Handler components will be exported as methods, with the name of the Component-type in lowercase as the method name.
The following example would result in a service with name `v1greet` and a single RPC method called `greeter`:
```swift
var content: some Component {
    Group("greet") {
        Greeter()
    }
}
```
Exported description of the gRPC service:
```protobuf
service v1greet {
    rpc greeter(/**/) returns (/**/);
}
```

### Custom service names
The service name can be explicitly set by using the `ServiceName` modifier. The following example...
```swift
var content: some Component {
    Group("greet") {
        Greeter()
        Text("Hallo Welt")
    }.serviceName("GreetService")
}
```
... would produce this description of the gRPC service:
```protobuf
service GreetService {
    rpc greeter(/**/) returns (/**/);
    rpc text(/**/) returns (/**/);
}
```

Since the Apodini Component tree needs to be flattend to be representable as a gRPC service, only the `ServiceName` applied at the deepest level of the tree will be considered. Thus, the following example would result in the same output as shown above:
```swift
var content: some Component {
    Groupd("messaging") {
        Group("greet") {
            Greeter()
            Text("Hallo Welt")
        }.serviceName("GreetService")
    }.serviceName("MessagingService")
}
```

### Custom method names
The names of methods that the Components are exported to can also be explicitly set by using the `MethodName` modifier. The following example...
```swift
var content: some Component {
    Group("greet") {
        Greeter().methodName("greetByName")
        Text("Hallo Welt")
    }.serviceName("GreetService")
}
```
... would produce this description of the gRPC service:
```protobuf
service GreetService {
    rpc greetByName(/**/) returns (/**/);
    rpc text(/**/) returns (/**/);
}
```

## Parameters
All `@Parameters` are dealt with in the same way for gRPC. In gRPC the only way a Component can receive parameters, is via the message payload. This means all parameters will be decoded from the payload of the message, no matter of which type a `@Parameter` is (`.body`, `.path`, etc.).

As a result, the exporters have to resolve any potential name clashes between parameters of different type. E.g., a Component might have two parameters called "name", but on being declared as a path parameter and the other being declared as a body parameter: 

```swift
struct Greeter: Component {
   @Parameter("name", .http(.body))
   var bodyName: String

   @Parameter("name", .http(.path))
   var pathName: String

   func handle() -> String {
       // ...
   } 
}
```

**TODO**: How to solve this? 
We might be able to use special sub-messages, e.g.:
```protobuf
service Greeter {
    rpc handle(GreeterMessage) returns (StringMessage);
}

message PathMessage {
    string name = 1:
}

message BodyMessage {
    string name = 1;
}

message GreeterMessage {
    PathMessage path = 1;
    BodyMessage body = 2;
}
```


## Field numbers
Protobuffers are using field numbers / field tags to uniquely identify each field of a message. By default, the gRPC exporters will enumerate all parameters in the order they are place in the source file:
```swift
struct Greeter: Component {
   @Parameter("name")
   var name: String

   @Parameter("age")
   var age: Int32

   func handle() -> String {
       // ...
   } 
}
```
Results in:
```protobuf
message GreeterMessage {
    string name = 1;
    int32 age = 2;
}
```

The same holds for non-primitive paramaters with nested data structures.

### Custom field numbers
Apodini also allows you to manually define field numbers. For parameters of Components, this can be done using the `gRPCParameterOptions.fieldTag`:
```swift
struct Greeter: Component {
   @Parameter("name", .gRPC(.fieldTag(2))
   var name: String
   // ...
}
```

For non-primitive parameters and nested data structures, this can be done using the `CodingKey`s of `Codable` structs. Please refer to the documentation of the ProtobufferCoding module [here](<./../../Sources/ProtobufferCoding/README.md>).