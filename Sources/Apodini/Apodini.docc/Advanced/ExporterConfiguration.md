# Configuration of Exporters

Extensive configuration options for Apodini Exporters.

<!--
                  
This source file is part of the Apodini open source project

SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>

SPDX-License-Identifier: MIT
             
-->

## Overview

The `configuration` variable of the `WebService` allows developers to specify various settings of the Apodini web service. The probably most important one is the configuration of the Exporters, so what interfaces of the declaratively defined web service are exposed. Of course, the DSL of Apodini should also allow the developer to configure the exporters themselves, so for example what Encoding/Decoding strategy should be used by the exporter.

This results in certain requirements that the ExporterConfiguration must fulfill. First, the exposed interfaces should be configurable via exporters as well as the exporters themselves. Furthermore, associated exporters, as for example the `REST` exporter and the `OpenAPI` exporter should be able to share their configuration without the need for the developer to pass the configuration twice.

### Exporter-specific Configuration

Apodini's DSL implements these requirements in the following way. This example shows the definition of the `REST` interface exporter that exposes the `WebService` via a RESTful API.

```swift
import Apodini
import ApodiniREST

public struct Example: WebService {
    public var configuration: Configuration { 
        REST()
    }
}
```

Furthermore, as stated by our requirements, exporters should be configurable. An example would be the custom specification of the Encoding strategy of the `REST` exporter. By default, the `REST` exporter uses a `JSONEncoder` with the `.prettyPrinted` and `.withoutEscapingSlashes` options and a `JSONDecoder` with only the standard options.

```swift
import Foundation
import Apodini
import ApodiniREST

public struct Example: WebService {
    private var jsonEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    public var configuration: Configuration { 
        REST(encoder: jsonEncoder)
    }
}
```

This can be done for all kinds of coding strategies, for example XML, but this requires the developer to write an extension for the respective coder which conforms to the `AnyEncoder` or `AnyDecoder` protocol of the `ApodiniREST` target. This protocol specifies a `func encode<E>(_ encodable: E, to body: inout ByteBuffer, headers: inout HTTPHeaders)` and a `func decode<D>(_ type: D.Type, from data: Data) throws -> D where D: Decodable` function that must be implemented by the user. This is required since the RESTful routes are handled by Vapor which requires such a function (via the `ContentEncoder` or `ContentDecoder` protocol). An example with XML Coders would be the following:

```swift
import Foundation
import Apodini
import ApodiniREST
import SotoXML

public struct Example: WebService {
    public var configuration: Configuration { 
        REST(encoder: XMLEncoder(), decoder: XMLDecoder())
    }
}

extension XMLEncoder: AnyEncoder {
    public func encode<E>(_ encodable: E, to body: inout ByteBuffer, headers: inout HTTPHeaders) throws where E: Encodable {
        headers.contentType = .xml
        try body.writeBytes(self.encode(encodable))
    }

    private func encode<E>(_ value: E) throws -> Data where E: Encodable {
        let element: XML.Element = try self.encode(value)
        return element.xmlString.data(using: .utf8)!
    }
}

extension XMLDecoder: AnyDecoder {
    public func decode<D>(_ type: D.Type, from data: Data) throws -> D where D: Decodable {
        let xmlElement = try XML.Element(xmlData: data)
        return try self.decode(type, from: xmlElement)
    }
}
```

This now encodes and decodes all messages coming from or to RESTful routes in the XML format. Of course, these coding configurations can be extended to an arbitrary coding format, the developer just needs to let the coder conform to the `AnyEncoder` or `AnyDecoder` protocol and therefore implement the respective coding functions.

Furthermore, the `REST` exporter provides a parameter to enable case-insensitive routing with the parameter `caseInsensitiveRouting`. By default, this parameter is set to `false`, conforming to the actual URL standards.

### Shared Configurations of Associated Exporters

A further requirement is the shared configuration of associated exporters. This might seems unintuitive at first, what exporters are actually dependent on each other, shouldn't they be independently exporting some kind of interface? As an answer, I state the `REST` and `OpenAPI` exporters. The `REST` exporter is completely independent and doesn't need the `OpenAPI` exporter at all. However, in the other way around this doesn't hold up. The `OpenAPI` exporter generates a description of a webservice and this webservice is required to be RESTful. Therefore, the `OpenAPI` exporter has a dependence on the `REST` exporter and can only "exist" when the parent `REST` exporter is present.

Here an example of these associated, or nested, exporters:

```swift
import Apodini
import ApodiniREST
import ApodiniOpenAPI

public struct Example: WebService {
    public var configuration: Configuration { 
        REST {
            OpenAPI()
        }
    }
}
```

This "nested" expression in the DSL of Apodini makes the specification of exporters very intuitive and doesn't allow for any errors, for example an `OpenAPI` exporter but no associated `REST` exporter. The "nesting" of associated exporters is implemented via Swift's `ResultBuilder`s, so it also allows for multiple associated exporters (will maybe get relevant in the future).

Furthermore, this syntax allows for the configuration of both exporters. The configuration of the "parent" exporter, so the `REST` exporter, is passed onto the "nested" `OpenAPI` exporter, so it for example can use the coding configuration of the `REST` exporter.

```swift
import Foundation
import Apodini
import ApodiniREST
import ApodiniOpenAPI

public struct Example: WebService {
    public var configuration: Configuration { 
        REST(encoder: JSONEncoder(), decoder: JSONDecoder()) {
            OpenAPI(outputFormat: .yaml,
                    outputEndpoint: "/oas",
                    swaggerUiEndpoint: "/oas-ui")
        }
    }
}
```

Another feature of this DSL is the prevention of wrongly passed associated exporters. For example, an associated `OpenAPI` exporter is only allowed if the coding format is JSON. So this is allowed (since the default coders are JSON)

```swift
REST {
    OpenAPI()
}
```

but this isn't

```swift
REST(encoder: XMLEncoder()) {
    OpenAPI()
}
```

This concept also extends to other associated exporters, so for example a `REST` exporter isn't allowed to have an associated `Protobuffer` exporter or a `WebSocket` exporter isn't allowed to have any associated exporters (at the moment). With that, Apodini's DSL prevents small accidental mistakes by the developer that are even enforced at compile-time (since Swift is a statically typed language).

Some other types of exporters (and associated exporters) can be seen in the following examples, the concept stays the same:

```swift
import Apodini
import ApodiniGRPC
import ApodiniProtobuffer

public struct Example: WebService {
    public var configuration: Configuration { 
        GRPC(integerWidth: .thirtyTwo) {
            Protobuffer()
        }
    }
}
```

Here the `Protobuffer` exporter also can't exist without the `GRPC` exporter, similar to `REST` and `OpenAPI` exporters.

```swift
import Apodini
import ApodiniWebSocket

public struct Example: WebService {
    public var configuration: Configuration { 
        WebSocket(path: "apodini/ws")
    }
}
```

## Topics

### Protocols

- ``WebService``
- ``Configuration``
