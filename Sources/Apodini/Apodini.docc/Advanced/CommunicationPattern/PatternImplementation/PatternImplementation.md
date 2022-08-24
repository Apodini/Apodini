# Pattern Implementation

Implemented communication patterns.

<!--
                  
This source file is part of the Apodini open source project

SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>

SPDX-License-Identifier: MIT
             
-->

## Overview

Apodini enables the developer to describe a functionality for a certain endpoint using ``Handler``s. Apodini's exporters try to export as much as possible of this functionality using the toolset provided by their respective protocols. In certain cases the protocol does not support all of the functionality described in the ``Handler``. That is when Apodini has to downgrade the functionality to fit the protocol's restrictions. Apodini automatically tries to find an alternative representation in the incompatible protocol so that the exported service does not become dysfunctional. Of course, the developer should be able to choose the exported pattern for each exporter individually if the automatic choice does not meet their needs.

In the rare cases where that is not possible, the developer may decide to hide this incompatible endpoint from a specific exporter on a ``Component``-level and provide an alternative implementation that is compatible with a more basic communication pattern.

## Support

In the future, the developer should be able to use Apodini's tooling without thinking about communication patterns and what protocols they want to support and still end up with fully functional services from all exporters.

Currently, most exporters do not support all communication patterns:

|           | Request-Response | Client-Side Stream | Service-Side Stream | Bidirectional Stream |
|-----------|------------------|--------------------|---------------------|----------------------|
| RESTful   | ✅                | ❌                  | ❌                   | ❌                    |
| gRPC      | ✅                | ✅                  | ❌                   | ❌                    |
| WebSocket | ✅                | ✅                  | ✅                   | ✅                    |
| GraphQL   | ✅                | ❌                  | ❌                   | ❌                    |
| HTTP      | ✅                | ✅                  | ✅                   | ✅                    |

### HTTP Streaming

Streaming via the HTTP interface exporter is implemented in two ways. Via HTTP/1.1, array-based streaming is available. Via HTTP/2, dynamic streaming is supported via HTTP/2 streams.

**HTTP/1.1 Array-based Streaming**

Multiple Apodini requests and responses can be colletively represented as a JSON array, which is used as the body of an HTTP request or response. As HTTP Request Headers can only be sent once, query parameters have to be represented as part of the JSON body.

The `SingleParameterHandler` (see below) could be supplied with the following HTTP body:

```json
[
    {
        "query": {
            "name": "Max"
        }
    },
    {
        "query": {
            "name": "Moritz"
        }
    }
]
```

```swift
struct SingleParameterHandler: Handler {
    @Parameter var name: String
    @Environment(\.connection) var connection: Connection


    func handle() -> Response<String> {
        print(name)

        if connection.state == .end {
            return .final("End")
        } else { // connection.state == .open
            return .nothing // Send no reponse to the client as the connection is not yet terminated
        }
    }
}
```

Thus, proper streaming is not supported via HTTP/1.1, as all of the requests have to be known a priori and are sent as one block.

**HTTP/2 Length-prefixed Streaming**

Via HTTP/2's streams, dynamic streaming is supported. Individual messages are length-prefixed, and the same encoding is used to represent query parameters in JSON as for the array-based streaming. A client implementing this lightweight protocol is provided (see `HTTP2StreamingClient`). Equivalently to Apodini Handlers on the server, client-side handlers can be implemented using `StreamingDelegate`s.

See the following example of a `StreamingDelegate` which can send requests to the `BidirectionalStreamingGreeter` handler.

```swift
struct BidirectionalStreamingGreeter1: Handler {
    @Parameter(.http(.query)) var country: String?
    
    @Apodini.Environment(\.connection) var connection
    
    func handle() -> Apodini.Response<String> {
        switch connection.state {
        case .open:
            return .send("Hello, \(country ?? "World")!")
        case .end, .close:
            return .end
        }
    }
    
    var metadata: AnyHandlerMetadata {
        Pattern(.bidirectionalStream)
        Operation(.create)
    }
}
```swift

```
struct CountryStruct: Codable {
    let country: String
}

final class GreeterDelegate: StreamingDelegate {
    typealias SRequest = DATAFrameRequest<CountryStruct>
    typealias SResponse = String
    var streamingHandler: HTTPClientStreamingHandler<GreeterDelegate>?
    var headerFields: BasicHTTPHeaderFields
    
    let countries = ["Germany", "USA"]
    var nextExpectedIndex = 0
    
    func handleInbound(response: String) {
        if !response.contains(countries[nextExpectedIndex]) {
            fatalError("Got the wrong country!")
        }
        nextExpectedIndex += 1
    }
    
    func handleStreamStart() {
        for country in countries {
            sendOutbound(request: DATAFrameRequest(CountryStruct(country: country)))
        }
        close()
    }
    
    func handleClose() {
        precondition(nextExpectedIndex == 2)
    }
    
    init(_ headerfields: BasicHTTPHeaderFields) {
        self.headerFields = headerfields
    }
}
```

For further examples, see the `HTTP2BidirectionalTests`, `HTTP2ServiceSideTests`, and `HTTP2ClientSideTests`.

## Topics

The following sections detail how different communication patterns can be implemented using the tools described in the previous chapter.

### Pattern Implementation

- <doc:RequestResponse>
- <doc:ClientSideStream>
- <doc:ServiceSideStream>
- <doc:BidirectionalStream>
