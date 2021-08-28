# Apodini's Building Blocks

This chapter introduces you to the most important building blocks of an Apodini web service.

<!--
                  
This source file is part of the Apodini open source project

SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>

SPDX-License-Identifier: MIT
             
-->

## Overview

An Apodini ``WebService`` consists of two parts. The `configuration` and the `content`. The former contains ``Configuration`` elements, which allow for modifying the ``Application``, i.e. the backbone of the ``WebService``.

The ``WebService``'s `content` holds a tree of ``Component``s. ``Component``s define the structure of your web service. At the leaves of this tree are ``Handler``s. Those define the interface and application logic of a certain endpoint of your web service. In other words, ``Component``s allow you to place ``Handler``s in a certain `Context`.

### Defining Structure

Let's take a quick look at code to see how ``Component``s work.

```swift
struct MyWebService: WebService {
    var configuration: Configuration {
        ...
    }

    var content: some Component {
        MyFirstHandler()
        Group("some", "path") {
            MySecondHandler()
            Group("elements") {
                MyThirdHandler()
            }
        }
    }
}
```
The `content` is a result builder. Each leaf we add to `content` is a new endpoint. In this example there are three endpoints, the application logic of which is defined by `MyFirstHandler`, `MySecondHandler`, and `MyThirdHandler` respectively.

We can easily factor out certain sub-components if we think they might be a good unit of reuse, or if we fear to lose overview. In this example, provide the complete content of another web service twice. Once in english and once in german under the `de` sub-route. 

```swift
struct MyLocalizedWebService: WebService {
    var configuration: Configuration {
        ...
    }

    var content: some Component {
        MyNestedComponent()
        Group("de") {
            MyNestedComponent(language: "de")
        }
    }
}

struct MyNestedComponent: Component {
    let language: String = "en"

    var content: some Component {
        MyOneHandler(language: language)
        Group("elements") {
            MyOtherHandler()
        }
    }
}
```

Of course, ``Group`` is just one of many ``Component``s. As mentioned previously, ``Component``s put endpoints in a certain `Context`. ``Group`` adds identifiers to the ``Context``s of its contained endpoints. In HTTP verbs that means it adds segments to the endpoint's path. Most ``Component``s are ``Modifier``s. They wrap a single ``Component`` or ``Handler`` and append to its `Context`. An example is ``Handler/operation(_:)``.

### Configuring Middleware

Apodini itself is middleware-agnostic. That is, you don't write ``Handler``s to operate on HTTP requests, to use JSON encoding or anything like that. The same applies to ``Component``s. ``Group`` is the basis for HTTP paths, but it is also the basis for gRPC service names or message identifiers in a global WebSocket endpoint. The building blocks that define how your web service looks like on the wire are ``InterfaceExporter``s. Most packages defining an ``InterfaceExporter`` also provide an accompanying ``Configuration`` you can add to your ``WebService``'s `configuration`. E.g. for `ApodiniHTTP`:

```swift
import ApodiniHTTP

struct MyLocalizedWebService: WebService {
    var configuration: Configuration {
        HTTP(decoder: myConfiguredDecoder)
    }

    var content: some Component {
        ...
    }
}
```

You can also have multiple ``InterfaceExporter``s configured at once.

Some exporters might even bring accompanying specification exporters. E.g. `ApodiniREST` has a compatible `ApodiniOpenAPI` exporter, which automatically generates and serves a fitting OpenAPI document for the service exported by `ApodiniREST`. Since `ApodiniOpenAPI` depends on `ApodiniREST`, it is a sub-configuration of the `ApodiniREST` exporter:

```swift
import ApodiniREST
import ApodiniOpenAPI

struct MyLocalizedWebService: WebService {
    var configuration: Configuration {
        REST {
            OpenAPI()
        }
    }

    var content: some Component {
        ...
    }
}
```

### Writing Application Logic

Now that you've seen how you can structure and export your web service, let's fill it with logic!

To do so, we have to implement ``Handler``s. ``Handler``s are structs that respond to incoming messages using a ``Handler/handle()-3440f`` function. Each connection gets its own independent instance of the ``Handler``. The ``Handler/handle()-3440f`` function uses ``Property``s defined by Apodini to get access to the frameworks features. The most important ``Property``s are ``Parameter`` and ``Environment``. The former provides you with middleware-agnostic access to input. The latter allows you to retrieve global and local information that either Apodini, a ``Configuration`` or you placed on the environment.

#### Defining Input

```swift
struct Greeter: Handler {
    @Parameter var name: String = "World"

    func handle() -> String {
        "Hello, \(name)!"
    }
}
```

This is just a very simple "Hello World" endpoint. If no parameter for `name` is found by the ``InterfaceExporter``, the default `"World"` is used. If we don't provide a default and the client doesn't provide a `name`, the framework would abort with a bad request error. Of course we can also have multiple ``Parameter``s on one endpoint. You can use any `Codable` type as a ``Parameter``. As shown in the example, the ``InterfaceExporter`` will use some default strategy to search for a fitting value in the client's request. That strategy completely depends on the exporter. E.g. the HTTP exporter would search for a HTTP query parameter named `name`, since it is a simple `String` parameter. If it were something that is not `CustomStringConvertible` it would try to decode it from the request's body. Exporter packages can define custom ``PropertyOption``s that let you customize various things.

```swift
struct CustomizedGreeter: Handler {
    @Parameter("country", .http(.path), .gRPC(.fieldTag(2)) var name: String = "World"

    @Parameter(.gRPC(.fieldTag(1)) var formal: Bool = false

    func handle() -> String {
        "\(formal ? "Greetings" : "Hi"), \(name)!"
    }
}
```

Now, the `name` parameter is called `country` for all exporters. Furthermore, it is no longer a query parameter for HTTP exporters, but appended to the path as a path parameter. For the gRPC exporter, we have customized the order in which the parameters are defined in the protobuf file.

> Tip: If you want to customize the position of path parameters, take a look at ``PathParameter``.

#### Defining Output

The output of your ``Handler`` is defined by the ``Handler/handle()-3440f``'s response type. That must be of type ``Content``, i.e. `Encodable`. ``Handler/handle()-3440f`` can be `async`, but if you have to work with NIO's `EventLoopFuture`s, you can also return those.

> Tip: If you want to return raw data on a single endpoint, e.g. for file-hosting, you can use the ``Blob`` ``Content`` type.

#### Working with the Environment

Often, the client's input is not enough to calculate a response. In that cases we use ``Environment``. It allows you to gain access to e.g. service classes. Items on the ``Environment`` are identified by `KeyPath`s. Usually, we store them on the ``Application``.

```swift
extension Application {
    var myService: MyService {
        guard let service = self.storage[\Application.myService] else {
            self.storage[\Application.myService] = MyService()
            return self.myService
        }
        return service
    }
}

struct MyWebService: WebService {
    var configuration: Configuration {
        EnvironmentValue(MyService(configuration: someConfig), \Application.myService)
        // ...
    }
    // ...
}
```

The extension on ``Application`` defines how the service class can be retrieved. This implementation tries to get it from the ``Application``'s ``Application/storage``, or returns a default version. However, you could also e.g. get it from a global variable. If you store it on the ``Application/storage``, you can use the ``EnvironmentValue`` ``Configuration`` to inject a different version.

```swift
struct MyHandler: Handler {
    @Parameter var name: String

    @Environment(\.myService) var myService

    func handle() -> String {
        myService.greet(name)
    }
}
```

You can then access the environment value on a ``Handler`` using the ``Environment`` property wrapper.


#### Throwing Errors

You can throw any `Error` from your ``Handler``'s ``Handler/handle()-3440f`` function. However, you should only throw ``ApodiniError``s. They provide guidance to ``InterfaceExporter``s what type of error it is and can be customized with e.g. HTTP error codes. To throw an ``ApodiniError``, you declare on your ``Handler`` that it ``Throws``:

```swift
struct MyThrowingHandler: Handler {
    @Throws(.forbidden,
            description: "UserService could not find the given UUID or user has no active subscription"
    ) var noSubscriptionError

    @Parameter var id: UUID
    
    @Environment(\.userService) var userService

    func handle() throws -> some ResponseTransformable {
        guard userService.isRegistered(id) else {
            throw noSubscriptionError(reason: "unknown id \(id)")
        }
        guard userService.hasValidSubscription(id) else {
            throw noSubscriptionError(reason: "account has no active subscription", .httpResponseStatus(.paymentRequired))
        }

        // ...
    }
}
```

Declaring the error as a ``Throws`` property on the ``Handler`` makes it available to specification document exporters such as ApodiniOpenAPI. You should declare all information that is known at startup-time there. If you want to add additional information depending on the client's input you can modify the error before throwing it by calling it as a function. ``ApodiniError`` can be customized with ``PropertyOption``s, to customize how certain exporters represent the error.

``ApodiniError`` has two different message types. The `reason` is public. It should not expose implementation details the client should not get hold of. The `description` can be more specific. ``InterfaceExporter``s should only expose the `description` in `DEBUG` mode or if explicitly configured to do so.


## Topics

### Defining Structure

The basic elements for defining the structure of your web service:

- ``Component``
- ``Modifier``
- ``Group``
- ``Handler/operation(_:)``

### Configuring Middleware

Here you can find information on ``InterfaceExporter``s you can use to build your web services:

- ``Configuration``
- <doc:WebSocket>
- <doc:ProtocolBuffers>

### Writing Application Logic

- ``Handler``
- ``Property``
- ``Parameter``
- ``PathParameter``
- ``Environment``
- ``PropertyOption``
- ``Content``
- ``Blob``
- ``EnvironmentValue``
- ``Storage``
- ``Application``
- ``ApodiniError``
- ``Throws``
