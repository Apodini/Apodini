# Request-Response

Usage of Request and Response pattern.

<!--
                  
This source file is part of the Apodini open source project

SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>

SPDX-License-Identifier: MIT
             
-->

## Overview

Request-Response is the simplest pattern. A simple hello world could look like this:

```swift
struct Greeter: Handler {
    @Parameter var name: String?

    func handle() -> String {
        "Hello, \(name ?? World)!"
    }
}
```

The above code does return `String` instead of an `Response<String>`. The following would result in the exact same behavior:

```swift
struct Greeter: Handler {
    @Parameter var name: String?

    func handle() -> Response<String> {
        .final("Hello, \(name ?? World)!")
    }
}
```

Of course for more advanced features (e.g. usage of database), the `handle` could also return an `EventLoopFuture<String>` or `EventLoopFuture<Response<String>>`.

