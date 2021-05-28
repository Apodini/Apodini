//
// Created by Andreas Bauer on 21.05.21.
//

/// The `AnyMetadata` protocol represents arbitrary Metadata.
/// This might be a `MetadataDefinition`, a `AnyMetadataBlock` or something else.
///
/// If you want to create new Metadata Definitions you may want to look at `MetadataDefinition`.
///
/// Furthermore Metadata is classified in terms of **WHERE** it can be declared:
/// - `AnyHandlerMetadata` represents arbitrary Metadata that can be declared on `Handler`s.
/// - `AnyWebServiceMetadata` represents arbitrary Metadata that can be declared on the `WebService`.
/// - `AnyComponentMetadata` represents arbitrary Metadata that can be declared on `Component`s.
///     Such Metadata can also be used on `Handler`s and on the `WebService` which both are Components as well,
///     as it inherits from `AnyHandlerMetadata`, `AnyWebServiceMetadata` and `AnyComponentOnlyMetadata`.
/// - `AnyComponentOnlyMetadata` represents arbitrary Metadata that can be declared on `Component` only,
///     meaning on all `Component`s  which are **not** `Handler`s or the `WebService`.
/// - `ContentMetadata` represents arbitrary Metadata that can be declared on `Content` types.
public protocol AnyMetadata {
    /// This method accepts the `SyntaxTreeVisitor` in order to parse the Metadata tree.
    /// The implementation should either forward the visitor to its content (e.g. in the case of a `AnyMetadataBlock`)
    /// or add the parsed Metadata to the visitor.
    ///
    /// - Parameter visitor: The `SyntaxTreeVisitor` parsing the Metadata tree.
    func accept(_ visitor: SyntaxTreeVisitor)
}

/// `AnyHandlerMetadata` represents arbitrary Metadata that can be declared on `Handler`s.
public protocol AnyHandlerMetadata: AnyMetadata {}
/// `AnyComponentOnlyMetadata` represents arbitrary Metadata that can be declared on `Component` only,
/// meaning on all `Component`s  which are **not** `Handler`s or the `WebService`.
public protocol AnyComponentOnlyMetadata: AnyMetadata {}
/// AnyWebServiceMetadata` represents arbitrary Metadata that can be declared on the `WebService`.
public protocol AnyWebServiceMetadata: AnyMetadata {}

/// `AnyComponentMetadata` represents arbitrary Metadata that can be declared on `Component`s.
/// Such Metadata can also be used on `Handler`s and on the `WebService` which both are Components as well,
/// as it inherits from `AnyHandlerMetadata`, `AnyWebServiceMetadata` and `AnyComponentOnlyMetadata`.
public protocol AnyComponentMetadata: AnyComponentOnlyMetadata, AnyHandlerMetadata, AnyWebServiceMetadata {}

/// `ContentMetadata` represents arbitrary Metadata that can be declared on `Content` types.
public protocol AnyContentMetadata: AnyMetadata {}
