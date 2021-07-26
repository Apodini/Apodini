# Hello, World!

A minimal Apodini web service.

## Overview

The following example defines a simple web service consisting of a greeting message.
Let's take a look to the simple usage of Apodini framework:

```swift
import Apodini
import ApodiniREST

struct Greeter: Handler {
    @Parameter var country: String?

    func handle() -> String {
        "Hello, \(country ?? "World")!"
    }
}

struct HelloWorld: WebService {
    var configuration: Configuration {
        REST()
    }

    var content: some Component {
        Greeter()
    }
}

HelloWorld.main()
```

### Import Package

It is required to import `Apodini` and `ApodiniREST`:
```swift
import Apodini
import ApodiniREST
```
It allows us to use the Apodini core functionalities and interface exporter for REST API.


### Create Simple Handler

We create our first `Handler` instance:
```swift
struct Greeter: Handler {
    @Parameter var country: String?

    func handle() -> String {
        "Hello, \(country ?? "World")!"
    }
}
```
A `Handler` is a `Component` within Apodini which exposes user-facing functionality. It always comes with a ``Handler/handle()-1xtna``function which is called every time a request reaches it.

> Tip: Practical usage of handlers: <doc:HandlerDelegation>.

Here, `Greeter` serves to handle an input data `country` as ``Parameter`` and respond with a `String` return type.

> Tip: See also: ``PathParameter`` express parameters that are exposed as part of the HTTP URL.

### Define Web Services

The following block includes the configuration and content of an Apodini web service.
```swift
struct HelloWorld: WebService {
    var configuration: Configuration {
        REST()
    }

    var content: some Component {
        Greeter()
    }
}
```
Each Apodini project consist of a `WebService` instance which describes the Web API.
It includes the `configuration` to configure services into Apodini project and `content` to define the structure of the web service.
Those components could be a collection of other `Component` instances or of `Handler` type.
In this case, we use REST configuration and put our `Greeter` handler.

> Tip: Learn more on exporters configuration: <doc:ExporterConfiguration>.

### Execute Apodini Web Service

We have to execute this line of code to start up an Apodini `WebService`.
```swift
HelloWorld.main()
```

### View Web Request in Action

Now you can send a request to see your new server in action!

Visit [http://localhost:8080/v1](http://localhost:8080/v1) will return:
```swift
Hello, World!
```
or [http://localhost:8080/v1?country=Italy](http://localhost:8080/v1?country=Italy):
```swift
Hello, Italy!
```

## Topics

### Delegate Handlers

- <doc:HandlerDelegation>

### Web Service Configuration
- <doc:ExporterConfiguration>
- ``EnvironmentObject``

### Protocols

- ``Component``
- ``Handler``
- ``WebService``
- ``Configuration``
- ``Parameter``
