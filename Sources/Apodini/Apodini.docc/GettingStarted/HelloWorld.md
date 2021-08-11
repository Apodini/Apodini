# Hello, World!

A minimal Apodini web service.

<!--
                  
This source file is part of the Apodini open source project

SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>

SPDX-License-Identifier: MIT
             
-->

## Overview

The following example defines a simple web service consisting of a greeting message.
Let's take a look to the simple usage of Apodini framework:

```swift
import Apodini
import ApodiniHTTP

struct Greeter: Handler {
    @Parameter var country: String?

    func handle() -> String {
        "Hello, \(country ?? "World")!"
    }
}

struct HelloWorld: WebService {
    var configuration: Configuration {
        HTTP()
    }

    var content: some Component {
        Greeter()
    }
}

HelloWorld.main()
```

### Import Package

We need to import `Apodini` and at least one package providing a ``Configuration`` which bootstraps an ``InterfaceExporter``. In our example, this package is `ApodiniHTTP`:
```swift
import Apodini
import ApodiniHTTP
```
By choosing `ApodiniHTTP`, we decide that our application-logic should be accessible using the HTTP protocol stack.


### Create a Simple Handler

We create our first `Handler` instance:
```swift
struct Greeter: Handler {
    @Parameter var country: String?

    func handle() -> String {
        "Hello, \(country ?? "World")!"
    }
}
```
A ``Handler`` is a ``Component`` within Apodini which exposes user-facing functionality. It always comes with a ``Handler/handle()-1xtna`` function which is called every time a request reaches it.

Our `Greeter` defines a ``Parameter`` called `country`. The parameter must be of type `String?`. Since that is an optional type, it can also be omitted from the request.

> Tip: See also: ``PathParameter`` express parameters that are exposed as part of the endpoint identifier (e.g. the HTTP URL).

The ``Handler/handle()-1xtna`` function uses the ``Parameter`` to generate a response. In our case, this response is also of type `String`.

### Define Web Services

The following block includes the configuration and content of an Apodini web service.
```swift
struct HelloWorld: WebService {
    var configuration: Configuration {
        HTTP()
    }

    var content: some Component {
        Greeter()
    }
}
```
Each Apodini project consist of a ``WebService`` instance which describes the Web API.
It includes the `configuration` and `content` to define the structure of the web service.
Those components could be a collection of other ``Component`` instances or of ``Handler`` type.
In this case, we use the `HTTP` configuration and put our `Greeter` Handler at the root of our web service.

<!-- TODO: more usage-focused guide | Tip: Learn more on exporters configuration: <doc:ExporterConfiguration>.  -->

### Execute Apodini Web Service

We have to execute this line of code to start up an Apodini `WebService`.
```swift
HelloWorld.main()
```

### View Web Request in Action

Now you can send a request to see your new server in action!

Visit [http://localhost:8080/v1](http://localhost:8080/v1) will return:
```swift
"Hello, World!"
```
or [http://localhost:8080/v1?country=Italy](http://localhost:8080/v1?country=Italy):
```swift
"Hello, Italy!"
```

Note that you don't just see `Hello, World!`, but `"Hello, World!"` as a string. That is because - by default - `ApodiniHTTP` encodes/decodes data as JSON.


## Topics

### Web Service Elements

- ``Component``
- ``Handler``
- ``WebService``
- ``Configuration``
- ``InterfaceExporter``

### Handler Properties
- ``Property``
- ``Parameter``
- ``PathParameter``
- ``Environment``
