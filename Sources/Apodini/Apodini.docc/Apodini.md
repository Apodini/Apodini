# ``Apodini``

A declarative, composable framework to build web services using Swift.

<!--
                  
This source file is part of the Apodini open source project

SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>

SPDX-License-Identifier: MIT
             
-->

## Overview

Apodini is an open source server side Swift framework completely written in Swift. It brings the declarative nature of SwiftUI to the server.

```swift
import Apodini
import ApodiniHTTP

struct Greeter: Handler {
    @Parameter var name: String?

    func handle() -> String {
        "Hello, \(name ?? "World")!"
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

Apodini is all about understandable and reusable code. However, two things make it really special:

* Thanks to its **declarative API**, the framework has insight into your code. This enables powerful automations with little runtime overhead.
* Apodini is not just about HTTP. It's **middleware-agnostic**. The protocols used for exporting your application logic are just a matter of configuration!

Apodini is a high level framework based on [SwiftNIO](https://github.com/apple/swift-nio). Its API makes use of the latest Swift language features such as result builders, property wrappers, and `async`/`await`. But don't worry, it also integrates well with the ecosystem of libraries around the [Vapor](https://vapor.codes) framework. Actually, many components - such as `ApodiniHTTP` are even based on Vapor itself!

## Topics

### Getting Started

Already convinced? Then check out our guides to Getting Started with Apodini!

- <doc:Installation>
- <doc:HelloWorld>

### Basics

If you want to get a bit more details first or need some support in building your first web service, here are some helpful resources for you.


- <doc:DSLComponents>
- <doc:UnitTesting>
- <doc:Jobs>

### Ecosystem

Here are some links to internal and external packages you might find helpful when building your web service.

- <doc:DatabaseConnection>
- <doc:PushNotifications>

### Advanced

Here you can find more advanced resources. You might even find internal documentation there.

- <doc:BuildingExporters>
- <doc:HandlerDelegation>
- <doc:CommunicationPattern>
- <doc:ProtocolBuffers>
- <doc:ExporterConfiguration>
- <doc:RetrieveRelationship>

### About

If you are more interested in Apodini's origin, meta-reasoning and related scientific work, this are the resources for you.

- <doc:About>
