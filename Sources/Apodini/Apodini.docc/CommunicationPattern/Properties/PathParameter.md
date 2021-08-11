# ``Apodini/PathParameter``

<!--
                  
This source file is part of the Apodini open source project

SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>

SPDX-License-Identifier: MIT
             
-->

@Metadata {
    @DocumentationExtension(mergeBehavior: append)
}

## Example

This code snippet provides an example of `PathParameter` property wrapper in a `Component`.

### Define a Handler with @Binding property.

```swift
struct GetRandom: Handler {
    @Binding var name: String
    
    func handle() -> String {
        return "random \(name)"
    }
}
```

With `@Binding` property we can reuse ``Handler``in different contexts.

### Use PathParameter to Access Input Data

```swift
struct ExampleComponent: Component {
    @PathParameter var name: String
    
    var content: some Component {
        Group("names") {
            Group($name) {
                GetRandom(name: $name)
            }
        }
    }
}
```
> Tip: Use ``Group`` to add path component to the URL.

### Register Component to the WebService

```swift
import Apodini
import ApodiniREST
import ApodiniOpenAPI

struct ExampleServer: WebService {
    var content: some Component {
        ExampleComponent()
    }
    
    var configuration: Configuration {
        REST()
    }
}

try XpenseServer.main()
```

## Topics

### <!--@START_MENU_TOKEN@-->Group<!--@END_MENU_TOKEN@-->

- <!--@START_MENU_TOKEN@-->``Symbol``<!--@END_MENU_TOKEN@-->
