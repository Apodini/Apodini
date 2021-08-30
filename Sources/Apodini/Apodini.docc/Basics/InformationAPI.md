# Information

The Information API maps middleware-specific metadata of the respective wire protocol into the framework
making it accessible inside a ``Handler``.

<!--

This source file is part of the Apodini open source project

SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>

SPDX-License-Identifier: MIT

-->

## Overview

Apodini provides the Information API to map middleware-specific metadata of a respective wire protocol into the framework.
Typically, an exporter or multiple exporters which share the same wire protocol define a set of ``Information`` instances.

The API provides two fundamental building blocks ``Information`` and ``InformationInstantiatable``.
``Apodini/Information`` represent an arbitrary protocol metadata which are stored in ``InformationSet``.
The ``InformationSet`` is accessible in the ``Connection`` of a request or can be supplied in the ``Response``.

A ``InformationInstantiatable`` is always implemented for a dedicated ``Information`` implementation.
It allows to provide a typed version for specific information.
For example, one would create a ``Apodini/Information`` instance to implement arbitrary HTTP headers as a string key value pair.
Then, a typed version of a specific http header can be implemented using ``InformationInstantiatable``.

### Accessing Information in a Request

The below example shows the supported ways of accessing Information from the current ``Connection``.

```swift
struct ExampleHandler: Handler {
    @Environment(\.connection) var connection: Connection

    func handle() -> String {
        let information = connection.information

        let info1 = information[ExampleInformation.self] // returns the typed ExampleInformation.Value if present
        let info2 = information[example: "dynamicKey"] // use custom overload to return raw value for the dynamic key (assuming string key)
        let info3 = information[ExampleInformationKey("dynamicKey")] // same as above, just not using the custom overload

        return "Hello World"
    }
}
```

### Including Information in the Response

```swift
struct ExampleHandler: Handler {
    func handle() -> Response<String> {
        // either instantiate a `InformationSet` by hand (e.g. via array literal)
        // or pass them directly into the response like presented here

        return .final(
            "Hello World",
            information: ExampleInformation(.someTypedValue), AnyExampleInformation(key: "dynamic", value: "custom")
        )
    }
}
```

### HTTP Headers

The `ApodiniHTTPProtocol` target (exposed through the exporter targets `ApodiniREST` and `ApodiniHTTP`) provides
the `AnyHTTPInformation` ``Apodini/Information`` implementation to map arbitrary http headers into the ``Handler`` implementation.
Further, it provides several typed versions of http headers (see ``InformationInstantiatable``):

- `Authorization`
- `Cookies`
- `ETag`
- `Expires`
- `RedirectTo`
- `WWWAuthenticate`

The following example demonstrates how one could parse a `Authorization` http header in a ``Handler``

```swift
struct ExampleHandler: Handler {
    @Environment(\.connection) var connection: Connection

    func handle() -> String {
        let information = connection.information

        let authorization = information[Authorization.self] // type version: Authorization.Value
        let untypedAuthorization = information[httpHeader: "Authorization"] // untyped version: AnyHTTPInformation

        return ...
    }
}
```

### Information Classes

Relevant only to the parties who implement their own ``Apodini/Information`` are ``InformationClass``es.
All information is organized or grouped into one or multiple ``InformationClass``.
As the ``Apodini/Information`` implementation itself often times resides in the individual targets which implement support for a dedicated wire protocol, it isn't easy for other ``InterfaceExporter``s to access ``Information`` in way which doesn't require dependence on those packages.

An ``Apodini/Information`` implementation conforms to one or more ``InformationClass``es (see the ``InformationClass`` for more information how this conformance is achieved). An ``InterfaceExporter`` can the query those ``InformationClass`` when mapping the ``InformationSet`` to the respective response.

The core Apodini target provides the following default ``InformationClass``es: ``StringKeyedEncodableInformationClass`` and ``StringKeyedStringInformationClass``.

## Topics

### Information


- ``Apodini/Information``
- ``InformationInstantiatable``

### Accessing the Information of a request

- ``Connection/information``

### Returning Information in a response

- ``Response/send(_:information:)-49uo5``
- ``Response/send(_:information:)-72126``
- ``Response/send(_:status:information:)-1u9zr``
- ``Response/send(_:status:information:)-8djh5``
- ``Response/final(_:information:)-6pe1o``
- ``Response/final(_:information:)-6pe1o``
- ``Response/final(_:status:information:)-3hsdh``
- ``Response/final(_:status:information:)-1fwar``
- ``Response/end(status:information:)-1ingx``
- ``Response/end(status:information:)-1ingx``

### Implementing Information

- ``Information``
- ``InformationInstantiatable``
- ``InformationKey``
- ``InformationClass``
- ``StringKeyedEncodableInformationClass``
- ``StringKeyedStringInformationClass``
