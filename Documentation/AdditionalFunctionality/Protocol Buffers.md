![document type: vision](https://apodini.github.io/resources/markdown-labels/document_type_vision.svg)

# Protocol Buffers

Protocol buffers are Google's language-neutral, platform-neutral, extensible mechanism for serializing structured data. [Source](https://developers.google.com/protocol-buffers/)
The `Apodini.ProtobufferInterfaceExporter` exposes a Protobuffer declaration of your `Apodini.WebService` in accordance to Google's [proto3 Language Guide](https://developers.google.com/protocol-buffers/docs/proto3).

The declaration `webservice.proto` is available at `apodini/webservice.proto`.

## Translation

We shall look into some examples of how `Apodini.ProtobufferInterfaceExporter` translates `Apodini.Handler`s into Protobuffer `Service`s and `Message`s.

...

## Known Issues

Enumerations are not supported.
