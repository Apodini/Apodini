![document type: vision](https://apodini.github.io/resources/markdown-labels/document_type_vision.svg)

# Protocol Buffers

Protocol buffers are Google's language-neutral, platform-neutral, extensible mechanism for serializing structured data. [Source](https://developers.google.com/protocol-buffers/)

When we use **gRPC**, we mean that this part of the program is responsible for the communication, i.e., remote procedure calls.
When we use **protocol buffers** or **Protobuffer**, we mean that this part of the program is responsible to work with Google's IDL.

## Exporters

The `Apodini.ProtobufferInterfaceExporter` exposes a Protobuffer declaration of your `Apodini.WebService` in accordance to Google's [proto3 Language Guide](https://developers.google.com/protocol-buffers/docs/proto3).
The declaration `webservice.proto` is available at `apodini/webservice.proto`.

The `Apodini.GRPCInterfaceExporter` exposes endpoints for gRPC clients.
The `webservice.proto` declaration shall be used to create a gRPC client that can communicate with your `Apodini.WebService` without any more work.

## Translation

We will look into some examples of how `Apodini.ProtobufferInterfaceExporter` translates `Apodini.Handler`s into protocol buffer `Service`s and `Message`s.

...

## Options

...

## Known Issues

Swift enumerations are not supported.
