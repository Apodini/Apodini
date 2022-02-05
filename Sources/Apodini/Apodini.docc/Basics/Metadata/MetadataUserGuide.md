# Metadata User Guide

A guide on how to use the Metadata system from the perspective of a user writing a web service.

<!--

This source file is part of the Apodini open source project

SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>

SPDX-License-Identifier: MIT

-->

## Overview

This guide introduces the most important features of the Apodini Metadata system. It is primarily targeted
towards users of the Metadata system, but can also be used by Metadata Providers to get an overview
of the Metadata system.

## Declaration Blocks

Apodini provides Metadata Declaration Blocks on the following types: ``Component``, ``WebService``, ``Handler``
and ``Content`` (Note that the `metadata` property for ``Content`` types is static). 
Inside those Declaration Blocks you can place any applicable Metadata instance to apply it to the respective element.  
Below shows the Metadata Declaration Blocks for all the above-mentioned protocols.

```swift
struct ExampleWebService: WebService {
    // ...
    var metadata: Metadata {
        // ...
    }
}

struct ExampleComponent: Component {
    // ...
    var metadata: Metadata {
        // ...
    }
}

struct ExampleHandler: Handler {
    // ...
    var metadata: Metadata {
        // ...
    }
}

struct ExampleContent: Content {
    // ...
    static var metadata: Metadata {
        // ...
    }
}
```

Some Metadata Definitions might only be available on a subset of the above Metadata Declaration Blocks.

Looking at the example of the predefined ``HandlerDescriptionMetadata`` Metadata which can be used in all the above Metadata Declaration
Blocks, to add a textual description to the respective component. Adding a ``HandlerMetadataNamespace/Description`` Metadata to a ``Handler`` could look like the following: 

```swift
struct ExampleHandler: Handler {
    func handle() -> String {
        "Hello World!"
    }

    var metadata: Metadata {
        Description("This Endpoint serves a message to the world!")
    }
}
```

## Metadata Blocks

Metadata Blocks are a way of grouping your Metadata Declaration such that it may improve code readability or introduce
any user defined semantics to the reader. Metadata Blocks are functionally not different to Metadata Declarations made
without Metadata Blocks.  

The special `Block` Metadata is available in all the above Metadata Declaration Blocks.  
It may be used as follows:

```swift
struct ExampleHandler: Handler {
    // ...
    var metadata: Metadata {
        // ...
        Block {
            Description("This Endpoint serves a message to the world!")
        }
    }
}
```

## Reusable Metadata Blocks

In some situations it might make sense to create Metadata Declarations which are independent of the component(s)
where they are used. Reasons may be to declutter the Metadata Declaration of your component or to reuse certain
Metadata on several components.  
Apodini provides Reusable Metadata Blocks for such circumstances. There are the following protocols available,
depending on where you want to apply your Metadata Block:

- ``HandlerMetadataBlock``
- ``WebServiceMetadataBlock``
- ``ComponentMetadataBlock``
- `ContentMetadataBlock`

An example `HandlerMetadataBlock` might look like the following:

````swift
struct ReusableExampleMetadata: HandlerMetadataBlock {
    var metadata: Metadata {
        // ...
    }
}

struct ExampleHandler: Handler {
    // ...
    var metadata: Metadata {
        ReusableExampleMetadata()
    }
}
````

## Restricted Metadata Blocks


Chapter `Metadata Blocks` introduced the general purpose Metadata Block `Block`.
Metadata Providers might choose to provide custom named Metadata Blocks which are restricted to only contain
certain types of Metadata.

You might imagine a Restricted Metadata Block called `Descriptions` which is restricted to only contain
``HandlerDescriptionMetadata`` Metadata (and may also contain nested `Descriptions` Blocks).  
Such a Block may be used like the following: 

```swift
struct ExampleHandler: Handler {
    // ...
    var metadata: Metadata {
        // ...
        Descriptions {
            Description("This is a Example Handler!")
        }
    }
}
```

## Component and Handler Modifiers

Apodini offers a range of ``Component`` and ``Handler`` Modifiers which can be used to add additional Metadata
to the respective Component. The following Modifiers are provided:

- ``Component/metadata(@MetadataBuilder:)``
- ``Component/metadata(_:)``
- ``Handler/metadata(@MetadataBuilder:)``
- ``Handler/metadata(_:)-154i8``

For both ``Component`` and ``Handler`` there are each two `.metadata` modifiers which can be used
to either add a specific instance of Metadata or add Metadata Declaration Blocks to the respective Component.

Below are two examples demonstrating on how to use each of those Modifiers to add a `Description` Metadata
to the Handler in the Component Tree:

```swift
struct ExampleComponent: Component {
    var content: some Component {
        ExampleHandler()
            .metadata(Description("Description for the predefined `ExampleHandler`"))
    }
}

struct ExampleComponent: Component {
    var content: some Component {
        ExampleHandler()
            .metadata {
                Description("Description for the predefined `ExampleHandler`")
                // ...
            }
    }
}
```

## Conditional Metadata 

The Metadata DSL allows for `if`, `if/else` and `switch` control flow statements.
This can be used to conditionally construct Metadata depending on arbitrary state.  
Note that Metadata Declaration Blocks are only evaluated once at startup. Therefore, it is sensible
to base the conditions only on state which is fixed after initialization.

```swift
struct ExampleHandler: Handler {
    var experimental: Bool
    // ...
    var metadata: Metadata {
        if experimental {
        Description("Note: The new experimental version of the Handler introduces breaking changes!")
        } else {
            Description ("This Handler serves as a example!")
        }
    }
}
```

## Loops

With Swift 5.4, the Metadata DSL allows for usage of `for .. in ..` loops to construct multiple Metadata Declarations.

```swift
struct ExampleHandler: Handler {
    // ...
    var metadata: Metadata {
        for i in 0...10 {
            // ...
        }
    }
}
```

## Topics

### Web Service Elements

- ``Component``
- ``Handler``
- ``WebService``
- ``Content``

### Metadata Blocks

- ``ComponentMetadataBlock``
- ``HandlerMetadataBlock``
- ``WebServiceMetadataBlock``
<!-- - `ContentMetadataBlock` -->

### Restricted Metadata Blocks

- ``RestrictedComponentMetadataBlock``
- ``RestrictedHandlerMetadataBlock``
- ``RestrictedWebServiceMetadataBlock``
<!-- - `RestrictedContentMetadataBlock` -->

### Metadata Modifier

- ``Component/metadata(@MetadataBuilder:)``
- ``Component/metadata(_:)``
- ``Handler/metadata(@MetadataBuilder:)``
- ``Handler/metadata(_:)-154i8``

### Metadata built into the Apodini core package

- ``Apodini/HandlerDescriptionMetadata``
- ``Apodini/WebServiceDescriptionMetadata``
- ``Apodini/OperationHandlerMetadata``
- ``Apodini/CommunicationPatternMetadata``
- ``Apodini/WebServiceVersionMetadata``
- ``Apodini/DelegateMetadata``
- ``Apodini/GuardMetadata``
- ``Apodini/ResetMetadata``
