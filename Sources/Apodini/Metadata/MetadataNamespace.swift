//
// Created by Andreas Bauer on 16.05.21.
//

/// The `HandlerMetadataNamespace` can be used to define a appropriate
/// Name for your `HandlerMetadataDefinition` in a way that avoids Name collisions
/// on the global Scope.
///
/// Given the example of `DescriptionHandlerMetadata` you can define a Name like the following:
/// ```swift
/// extension HandlerMetadataNamespace {
///     public typealias Description = DescriptionHandlerMetadata
/// }
/// ```
///
/// Refer to `TypedHandlerMetadataNamespace` if you need access to the generic `Handler`
/// Type where the Metadata is used on.
public protocol HandlerMetadataNamespace {}

/// The `ComponentOnlyMetadataNamespace` can be used to define a appropriate
/// Name for your `ComponentOnlyMetadataDefinition` in a way that avoids Name collisions
/// on the global Scope.
///
/// Given the example of `DescriptionComponentOnlyMetadata` you can define a Name like the following:
/// ```swift
/// extension ComponentOnlyMetadataNamespace {
///     public typealias Description = DescriptionComponentOnlyMetadata
/// }
/// ```
///
/// Refer to `TypedComponentMetadataNamespace` if you need access to the generic `Component`
/// Type where the Metadata is used on.
public protocol ComponentOnlyMetadataNamespace {}

/// The `WebServiceMetadataNamespace` can be used to define a appropriate
/// Name for your `WebServiceMetadataDefinition` in a way that avoids Name collisions
/// on the global Scope.
///
/// Given the example of `DescriptionWebServiceMetadata` you can define a Name like the following:
/// ```swift
/// extension WebServiceMetadataNamespace {
///     public typealias Description = DescriptionWebServiceMetadata
/// }
/// ```
///
/// Refer to `TypedWebServiceMetadataNamespace` if you need access to the generic `WebService`
/// Type where the Metadata is used on.
public protocol WebServiceMetadataNamespace {}

/// The `ComponentMetadataNamespace` can be used to define a appropriate
/// Name for your `ComponentMetadataDefinition` in a way that avoids Name collisions
/// on the global Scope.
///
/// Given the example of `DescriptionComponentMetadata` you can define a Name like the following:
/// ```swift
/// extension ComponentMetadataNamespace {
///     public typealias Description = DescriptionComponentMetadata
/// }
/// ```
///
/// Refer to `TypedComponentMetadataNamespace` if you need access to the generic `Component`
/// Type where the Metadata is used on.
///
/// - Note: Refer `ComponentMetadataGroupNamespace` for very specific circumstances where using
///     `ComponentMetadataNamespace` should be avoided.
public protocol ComponentMetadataNamespace {}

/// The `ContentMetadataNamespace` can be used to define a appropriate
/// Name for your `ContentMetadataDefinition` in a way that avoids Name collisions
/// on the global Scope.
///
/// Given the example of `DescriptionContentMetadata` you can define a Name like the following:
/// ```swift
/// extension ContentMetadataNamespace {
///     public typealias Description = DescriptionContentMetadata
/// }
/// ```
///
/// Refer to `TypedContentMetadataNamespace` if you need access to the generic `Content`
/// Type where the Metadata is used on.
public protocol ContentMetadataNamespace {}


/// The `ComponentMetadataGroupNamespace` can be used to define a appropriate
/// Name for your `ComponentMetadataDefinition` specifically for the Namespace
/// of `ComponentMetadataGroup`s.
///
/// This is only necessary if you additionally have equivalent or similar Component-Only and Handler and/or WebService Metadata
/// which additionally share the same name in the `ComponentOnlyMetadataNamespace`, `HandlerMetadataNamespace` and
/// `WebServiceMetadataNamespace` (Such example is the `EmptyComponentMetadata`).
public typealias ComponentMetadataGroupNamespace = ComponentMetadataGroup


/// As the `HandlerMetadataNamespace` is accessible from `HandlerMetadataGroup`s,
/// there is no way to know the type of the `Handler` the Metadata will be used one
/// (as `MetadataGroup`s decouple Metadata Declaration from the actual Component declared with that Metadata).
///
/// If your `HandlerMetadataDefinition` needs access to the Generic `Handler` Type the Metadata is used on,
/// you can use `TypedHandlerMetadataNamespace` to force that said Metadata can only be declared directly
/// in `Handler` Metadata Declaration Blocks.
///
/// Given a `ExampleHandlerMetadata` which expects the `Handler` Type as the first generic type,
/// you cann add it to the Namespace the following way:
/// ```swift
/// extension TypedHandlerMetadataNamespace {
///     public typealias Example = ExampleHandlerMetadata<Self>
/// }
/// ```
///
/// Doing so will make the `Example` Metadata **not available** in `HandlerMetadataGroup`s.
/// If you want to make the Metadata available in those groups as well, relying on the
/// user to manually specify the `Handler` generic Type, declare a Name in `HandlerMetadataNamespace`
/// like the following:
/// ```swift
/// extension HandlerMetadataNamespace {
///     public typealias Example<H: Handler> = ExampleHandlerMetadata<H>
/// }
/// ```
/// Doing so is advised, as it gives the user the most flexible way of structuring their Metadata Declarations,
/// and reduces the confusion about naming availability.
public typealias TypedHandlerMetadataNamespace = Handler

/// As the `WebServiceMetadataNamespace` is accessible from `WebServiceMetadataGroup`s,
/// there is no way to know the type of the `WebService` the Metadata will be used one
/// (as `MetadataGroup`s decouple Metadata Declaration from the actual Component declared with that Metadata).
///
/// If your `WebServiceMetadataDefinition` needs access to the Generic `WebService` Type the Metadata is used on,
/// you can use `TypedWebServiceMetadataNamespace` to force that said Metadata can only be declared directly
/// in `WebService` Metadata Declaration Blocks.
///
/// Given a `ExampleWebServiceMetadata` which expects the `WebService` Type as the first generic type,
/// you cann add it to the Namespace the following way:
/// ```swift
/// extension TypedWebServiceMetadataNamespace {
///     public typealias Example = ExampleWebServiceMetadata<Self>
/// }
/// ```
///
/// Doing so will make the `Example` Metadata **not available** in `WebServiceMetadataGroup`s.
/// If you want to make the Metadata available in those groups as well, relying on the
/// user to manually specify the `WebService` generic Type, declare a Name in `WebServiceMetadataNamespace`
/// like the following:
/// ```swift
/// extension WebServiceMetadataNamespace {
///     public typealias Example<W: WebService> = ExampleWebServiceMetadata<W>
/// }
/// ```
/// Doing so is advised, as it gives the user the most flexible way of structuring their Metadata Declarations,
/// and reduces the confusion about naming availability.
public typealias TypedWebServiceMetadataNamespace = WebService

/// As the `ComponentMetadataNamespace` is accessible from `ComponentMetadataGroup`s,
/// there is no way to know the type of the `Component` the Metadata will be used one
/// (as `MetadataGroup`s decouple Metadata Declaration from the actual Component declared with that Metadata).
///
/// If your `ComponentMetadataDefinition` needs access to the Generic `Component` Type the Metadata is used on,
/// you can use `TypedComponentMetadataNamespace` to force that said Metadata can only be declared directly
/// in `Component` Metadata Declaration Blocks.
///
/// Given a `ExampleComponentMetadata` which expects the `Component` Type as the first generic type,
/// you cann add it to the Namespace the following way:
/// ```swift
/// extension TypedComponentMetadataNamespace {
///     public typealias Example = ExampleComponentMetadata<Self>
/// }
/// ```
///
/// Doing so will make the `Example` Metadata **not available** in `ComponentMetadataGroup`s.
/// If you want to make the Metadata available in those groups as well, relying on the
/// user to manually specify the `Component` generic Type, declare a Name in `ComponentMetadataNamespace`
/// (and/or `ComponentOnlyMetadataNamespace`) like the following:
/// ```swift
/// extension ComponentMetadataNamespace {
///     public typealias Example<C: Component> = ExampleComponentMetadata<C>
/// }
/// ```
/// Doing so is advised, as it gives the user the most flexible way of structuring their Metadata Declarations,
/// and reduces the confusion about naming availability.
public typealias TypedComponentMetadataNamespace = Component

/// As the `ContentMetadataNamespace` is accessible from `ContentMetadataGroup`s,
/// there is no way to know the type of the `Content` the Metadata will be used one
/// (as `MetadataGroup`s decouple Metadata Declaration from the actual Content declared with that Metadata).
///
/// If your `ContentMetadataDefinition` needs access to the Generic `Content` Type the Metadata is used on,
/// you can use `TypedContentMetadataNamespace` to force that said Metadata can only be declared directly
/// in `Content` Metadata Declaration Blocks.
///
/// Given a `ExampleContentMetadata` which expects the `Content` Type as the first generic type,
/// you cann add it to the Namespace the following way:
/// ```swift
/// extension TypedContentMetadataNamespace {
///     public typealias Example = ExampleContentMetadata<Self>
/// }
/// ```
///
/// Doing so will make the `Example` Metadata **not available** in `ContentMetadataGroup`s.
/// If you want to make the Metadata available in those groups as well, relying on the
/// user to manually specify the `Content` generic Type, declare a Name in `ContentMetadataNamespace`
/// like the following:
/// ```swift
/// extension ContentMetadataNamespace {
///     public typealias Example<C: Content> = ExampleContentMetadata<C>
/// }
/// ```
/// Doing so is advised, as it gives the user the most flexible way of structuring their Metadata Declarations,
/// and reduces the confusion about naming availability.
public typealias TypedContentMetadataNamespace = Content
