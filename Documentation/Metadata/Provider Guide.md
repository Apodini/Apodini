![documentation](https://apodini.github.io/resources/markdown-labels/document_type_documentation.svg)

# Metadata DSL: Provider Guide

In the following guide, we want to highlight all the necessary steps to create your own Metadata Definition.
The guide will demonstrate each step using the example of a `Description` Metadata, which should be available
on `Handler`s and the `WebService` to define a textual description of the respective Component,
which could be used by Tool generating WebService Documentation (like the `OpenAPIExporter`).

## 0. Creating the `ContextKey`

The Metadata DSL system currently relies on the usage of `ContextKey`s to store and identify
Metadata with the respective Component. Therefore, the first step is to define
a Type conforming to `ContextKey` or `OptionalContextKey`. Withing that type you need to define
the Type of the stored value, a potential default value and optionally logic on how to reduce
multiple Metadata Declarations.   
The Type itself is used as an identifier to retrieve the stored Metadata Declaration.

For our example of a `Description` Metadata we can define a `OptionalContextKey` like the following:

```swift
struct DescriptionMetadataContextKey: OptionalContextKey {
    typealias Value = String
}
```

The above declaration uses the standard implementation of the `reduce` method, therefore
relying on the default hierarchy when encountering multiple declarations of the same Metadata.  
Overriding the `reduce` method can be especially useful when working with numbers, to get the maximum or minimum,
or appending values when working with array type ContextKeys.

## 1. Creating the `Metadata Definition`

Next up we need to deal with creating the actual Metadata Definition.  
When creating Metadata Definitions, the `MetadataDefinition` protocol is the fundamental build block
you will work with. Apodini provides several `MetadataDefinition` protocols, depending on **where**
you want your Metadata to be applicable. The following ones are available:

* `HandlerMetadataDefinition`: By conforming to this protocol, you make your Metadata Definition available
  inside the `Handler` Metadata Declaration Blocks.
* `WebServiceMetadataDefinition`: By conforming to this protocol, you make your Metadata Definition available
  inside the `WebService` Metadata Declaration Blocks.
* `ComponentMetadataDefinition`: By conforming to this protocol, you make your Metadata Definition available
  inside the `Component` Metadata Declaration Blocks, including those of `WebService` and `Handler`s.
* `ContentMetadataDefinition`: By conforming to this protocol, you make your Metadata Definition available
  inside the `Content` Metadata Declaration Blocks.
* `ComponentOnlyMetadataDefinition`: By conforming to this protocol, you make your Metadata Definition available
  inside the `Component` (and only `Component`) Metadata Declaration Blocks.

Your Metadata Definition can conform to any combination of the above protocols, to make it available
in the respective declaration blocks. Note that the `ComponentMetadataDefinition` is already
a combination of the `HandlerMetadataDefinition`, `WebServiceMetadataDefinition` and `ComponentOnlyMetadataDefinition`
protocols.

In our example, we want our Description Metadata to be declarable on `Handler`s and the `WebService`.
We do this by conforming to both the `HandlerMetadataDefinition` and `WebServiceMetadataDefinition` protocol.  
As required by the `MetadataDefinition` we will need to define our `ContextKey` in the `Key` typealias,
and implement the `value` property holding the stored Metadata.

```swift
struct DescriptionMetadata: HandlerMetadataDefinition, WebServiceMetadataDefinition {
    typealias Key = DescriptionMetadataContextKey
    
    var value: String // type equals to Key.Value
    
    init(_ description: String) {
        self.value = description
    }
}
```

Note that your Type name can and should be pretty descriptive. This will not be the name which is later used
for the Metadata Declaration. The Metadata DSL proposes the concept of the Metadata Namespaces described in the next
chapter which allow for more flexible naming, incorporating more natural language for the DSL.

## 2. Adding the Definition to the appropriate `Metadata Namespace`

Metadata Namespaces are a way of providing more descriptive and natural naming while reducing
potential naming conflicts.
This is done by defining a typealias in the respective Namespace.
Each type of Metadata Definition (e.g. a `HandlerMetadataDefinition`) has its own namespace
(e.g. `HandlerMetadataNamespace`), allowing to reuse the same name in different namespaces
for similar Metadata (e.g. there might be differing `Description` Metadata for Component descriptions
and Handler descriptions).

### 2.1. Standard Metadata Namespaces

For each available MetadataDefinition, Apodini defines the respective Metadata Namespace:

* `HandlerMetadataNamespace`: Namespace available in the metadata declaration blocks of the `Handler` or
  the `HandlerMetadataBlock` protocol.
* `WebServiceMetadataNamespace`: Namespace available in the metadata declaration blocks of the `WebService` or
  the `WebServiceMetadataBlock` protocol.
* `ComponentMetadataNamespace`: Namespace available in the metadata declaration blocks of the `Component`, 
  `Handler` and `WebService` protocols, as well as in the corresponding Metadata Block protocols: 
  `ComponentMetadataBlock`, `HandlerMetadataBlock`, `WebServiceMetadataBlock` and `ComponentOnlyMetadataBlock`.
* `ContentMetadataNamespace`: Namespace available in the metadata declaration blocks of the `Content` or
  the `ContentMetadataBlock` protocol.
* `ComponentOnlyMetadataNamespace`: This namespace should be used for `ComponentOnlyMetadataDefinition`s, as names defined
here have certain precedence over names defined in `ComponentMetadataNamespace` in places where it matters.
  Though, be aware that names defined here are still available in the metadata declaration blocks of 
  `Component`, `Handler`, `WebService` and `ComponentOnlyMetadataBlock` protocols.

For our `DescriptionMetadata` we want to use the name `Description`.
Our metadata conforms to `HandlerMetadataDefinition` and `WebServiceMetadataDefinition`,
therefore we need to declare our typealias in both the `HandlerMetadataNamespace` and the
`WebServiceMetadataNamespace`:

```swift
extension HandlerMetadataNamespace {
    typealias Description = DescriptionMetadata
}

extension WebServiceMetadataNamespace {
    typealias Description = DescriptionMetadata
}
```

A user could now use the `Description` Metadata as follows:
```swift
struct  TestHandler: Handler {
  func handle() -> String {
    "Hello World!"
  }
  
  var metadata: Metadata {
    Description("The TestHandler serves as a Hello World Endpoint!")
    // ...
  }
}
```

### 2.2. Typed Metadata Namespaces

In certain cases it might be useful or mandatory to retrieve the generic type of the component the Metadata
is declared on. As this information is not available with the regular Metadata Namespaces, Apodini provides the
following typed Metadata Namespaces, which allows to access the Type the Metadata is used on.  
The following Typed Metadata Namespaces are available:

- `TypedHandlerMetadataNamespace`
- `TypedWebServiceMetadataNamespace`
- `TypedComponentMetadataNamespace`
- `TypedContentMetadataNamespace`

You may note that there is no `TypeComponentOnlyMetadataNamespace` as it would be equivalent to
the `TypedComponentMetadataNamespace`.

We now assume a modified Handler Description Modifier which expects the Handler type as the first generic type
(e.g. to incorporate the type information into the description):
```swift
struct HandlerDescriptionMetadata<H: Handler>: HandlerMetadataDescription {
  // ...
}
```

Now we can define the name as follows:
```swift
extension TypedHandlerMetadataNamespace {
  typealias Description = HandlerDescriptionMetadata<Self>
}
```


This method allows to transparently insert the generic type

Be aware, that our `Description` Metadata is now only available inside Metadata Declaration Blocks of the `Handler`
protocol. To ensure greatest flexibility you should additionally add a typealias to the regular
`HandlerMetadataNamespace` so that your Metadata is still available in `HandlerMetadataBlock`s.

```swift
extension HandlerMetadataNamespace {
  typealias Description<H: Handler> = HandlerDescriptionMetadata<H>
}
```

This allows the user to still use your Metadata inside `HandlerMetadataBlock` though with the additional 
overhead of manually specifying the generic type.

<!--
### 2.3. Component Metadata Block Namespaces

% TODO `ComponentMetadataBlockNamespace`
-->

## 3. Define a `Restricted Metadata Block`

By default, the user can use the `Block` metadata to group arbitrary (according to the respective Metadata Declaration Block
it is used on) Metadata for better overview.
`Block` serves as a general purpose way of grouping Metadata Declarations.  
Restricted Metadata Blocks are now a way to provide custom Metadata Blocks which only allow for a specific
Metadata Declaration (and nesting the same Restricted Metadata Blocks).  
Apodini provides the following different `RestrictedMetadataBlock`s:

* `RestrictedHandlerMetadataBlock<RestrictedContent: AnyHandlerMetadata>`
* `RestrictedWebServiceMetadataBlock<RestrictedContent: AnyWebServiceMetadata>`
* `RestrictedComponentMetadataBlock<RestrictedContent: AnyComponentMetadata>`
* `RestrictedContentMetadataBlock<RestrictedContent: AnyContentMetadata>`
* `RestrictedComponentOnlyMetadataBlock<RestrictedContent: AnyComponentOnlyMetadata>`

Creating such a Restricted Metadata Block is only a matter of declaring another 
extension for the appropriate Namespace. For our original `DescriptionMetadata`
example we would do the following:

```swift
extension HandlerMetadataNamespace {
  typealias Descriptions = RestrictedHandlerMetadataBlock<DescriptionMetadata>
}

extension WebServiceMetadataNamespace {
  typealias Descriptions = RestrictedWebServiceMetadataBlock<DescriptionMetadata>
}
```

A user can now use our `Descriptions` Block to group all occurrences of our `Description`
Metadata (which doesn't make really sense in this example, but works for demonstration purposes).

```swift
struct  TestHandler: Handler {
  func handle() -> String {
    "Hello World!"
  }
  
  var metadata: Metadata {
    // ...
    Descriptions {
      Description("The TestHandler serves as a Hello World Endpoint!")
      // ...
    }
  }
}
```

## 4. Special purpose Metadata

The Metadata API provides some easy to use interfaces making the creation of common types of Metadata easier.
This section highlights the most important cases.

### 4.1. Metadata Definition providing a `DelegatingHandlerInitializer`

A given Metadata Declaration might want to boostrap a `DelegatingHandler`
(see [Delegating Handlers](https://github.com/Apodini/Apodini/wiki/Delegating-Handlers))
via the `DelegatingHandlerContextKey`
for the `Handler` it is declared on (this includes `HandlerMetadataDefinition`s but also `ComponenetMetadataDefinition`s
declared on all sorts of `Component`s).

The API differentiates between two cases, (a) a `MetadataDefinition` which adds the `DelegatingHandler` in addition
to its _standard_ Metadata value identified via the provided `MetadataDefinition.Key` or (b)
where the MetadataDefinition only contributes a `DelegatingHandler` and therefore the `MetadataDefinition.Key` is
equal to the `DelegatingHandlerContextKey`.

For both of the below-illustrated case, we assume the existence of a `FooBarDelegatingHandlerInitializer`.
See the article on [Delegating Handlers](https://github.com/Apodini/Apodini/wiki/Delegating-Handlers) for how
to create `DeleatginHandlers` and a appropriate `DelegatingHandlerInitializer`

Both cases are illustrated below.

#### 4.1.1. Providing a `DelegatingHandler` as an additional Metadata

We assume the existence of the `FooBar` Metadata with the existing string based `FooBarMetadataContextKey`:

```swift
struct FooBarMetadata: HandlerMetadataDefinition {
    typealias Key = FooBarMetadataContextKey
    
    var value: String
    
    init(foo: String) {
        self.value = foo
    }
}
```

Now you can declare conformance to the `DefinitionWithDelegatingHandler` protocol on the `FooBarMetadata`.
This will require us to implement the additional `var initializer: Initializer { get }` property providing
an instance of the discussed `DelegatingHandlerInitializer`.

```swift
struct FooBarMetadata: HandlerMetadataDefinition, DefinitionWithDelegatingHandler {
    typealias Key = FooBarMetadataContextKey
    
    var value: String
  
    var initializer = FooBarDelegatingHandlerInitializer()
    
    init(foo: String) {
        self.value = foo
    }
}
```

That's it. When the Metadata is parsed, it will now add the `value` for the `FooBarMetadataContextKey` and
the `initializer` for the `DelegatingHandlerContextKey` (both added with the `MetadataDefinition.scope`).

#### 4.1.2. Providing a `DelegatingHandler` as the primary Metadata

When creating a `MetadataDefinition` which solely contributes a `DelegatingHandlerInitializer`, in addition
to declaring conformance to the appropriate `MetadataDefinition` protocol (see [1.](#1-creating-the-metadata-definition))
you need to declare conformance to the `DefinitionWithDelegatingHandlerKey` protocol.  
This will require us to implement the additional `var initializer: Initializer { get }` property providing
an instance of the discussed `DelegatingHandlerInitializer`.

```swift
struct FooBarMetadata: HandlerMetadataDefinition, DefinitionWithDelegatingHandlerKey {
    var initializer = FooBarDelegatingHandlerInitializer()
  
    init() {
      // ...
    }
}
```
