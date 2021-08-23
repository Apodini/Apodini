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
struct GetName: Handler {
    @Binding var name: String
    
    func handle() -> String {
        return "The name is \(name)!"
    }
}
```

With the ``Binding`` property we can reuse ``Handler``s in different contexts. One option is
to fill the ``Binding`` with a ``PathParameter``.

### Use PathParameter to Access Input Data

```swift
struct ExampleComponent: Component {
    @PathParameter var name: String
    
    var content: some Component {
        Group("names") {
            Group($name) {
                GetName(name: $name)
            }
            Group("vips") {
                Group("founders", "Apple") {
                    GetName(name: .constant("Steve Jobs"))
                }
            }
        }
    }
}
```
> Tip: Use ``Group`` to add path components to the URL.

### Register Component to the WebService

```swift
import Apodini
import ApodiniREST

struct ExampleServer: WebService {
    var content: some Component {
        ExampleComponent()
    }
    
    var configuration: Configuration {
        REST()
    }
}

ExampleServer.main()
```

## Topics

### <!--@START_MENU_TOKEN@-->Group<!--@END_MENU_TOKEN@-->

- <!--@START_MENU_TOKEN@-->``Symbol``<!--@END_MENU_TOKEN@-->
