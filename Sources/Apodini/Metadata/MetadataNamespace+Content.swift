//
// Created by Andreas Bauer on 28.08.21.
//

/// As the `ContentMetadataNamespace` is accessible from `ContentMetadataBlock`s,
/// there is no way to know the type of the `Content` the Metadata will be used on
/// (as `MetadataBlock`s decouple Metadata Declaration from the actual Content declared with that Metadata).
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
/// Doing so will make the `Example` Metadata **not available** in `ContentMetadataBlock`s.
/// If you want to make the Metadata available in those blocks as well, relying on the
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
