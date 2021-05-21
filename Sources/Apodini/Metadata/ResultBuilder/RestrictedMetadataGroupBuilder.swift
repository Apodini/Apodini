//
// Created by Andreas Bauer on 16.05.21.
//

// TODO docs?
#if swift(>=5.4)
@resultBuilder
public enum RestrictedMetadataGroupBuilder<Group: RestrictedMetadataGroup> {}
#else
@_functionBuilder
public enum RestrictedMetadataGroupBuilder<Group: RestrictedMetadataGroup> {}
#endif

// MARK: Restricted Handler Metadata Group
public extension RestrictedMetadataGroupBuilder where Group: HandlerMetadataGroup, Group.RestrictedContent: AnyHandlerMetadata {
    static func buildExpression(_ expression: Group.RestrictedContent) -> AnyHandlerMetadata {
        expression
    }

    static func buildExpression(_ expression: Group) -> AnyHandlerMetadata {
        expression
    }

    static func buildBlock(_ components: AnyHandlerMetadata...) -> AnyHandlerMetadata {
        AnyHandlerMetadataArrayWrapper(components)
    }
}

// MARK: Restricted Component-Only Metadata Group
public extension RestrictedMetadataGroupBuilder where Group: ComponentOnlyMetadataGroup, Group.RestrictedContent: AnyComponentOnlyMetadata {
    static func buildExpression(_ expression: Group.RestrictedContent) -> AnyComponentOnlyMetadata {
        expression
    }

    static func buildExpression(_ expression: Group) -> AnyComponentOnlyMetadata {
        expression
    }

    static func buildBlock(_ components: AnyComponentOnlyMetadata...) -> AnyComponentOnlyMetadata {
        AnyComponentOnlyMetadataArrayWrapper(components)
    }
}

// MARK: Restricted WebService Metadata Group
public extension RestrictedMetadataGroupBuilder where Group: WebServiceMetadataGroup, Group.RestrictedContent: AnyWebServiceMetadata {
    static func buildExpression(_ expression: Group.RestrictedContent) -> AnyWebServiceMetadata {
        expression
    }

    static func buildExpression(_ expression: Group) -> AnyWebServiceMetadata {
        expression
    }

    static func buildBlock(_ components: AnyWebServiceMetadata...) -> AnyWebServiceMetadata {
        AnyWebServiceMetadataArrayWrapper(components)
    }
}

// MARK: Restricted Component Metadata Group
public extension RestrictedMetadataGroupBuilder where Group: ComponentMetadataGroup, Group.RestrictedContent: AnyComponentMetadata {
    static func buildExpression(_ expression: Group.RestrictedContent) -> AnyComponentMetadata {
        expression
    }

    static func buildExpression(_ expression: Group) -> AnyComponentMetadata {
        expression
    }

    static func buildBlock(_ components: AnyComponentMetadata...) -> AnyComponentMetadata {
        AnyComponentMetadataArrayWrapper(components)
    }
}

// MARK: Restricted Content Metadata Group
public extension RestrictedMetadataGroupBuilder where Group: ContentMetadataGroup, Group.RestrictedContent: AnyContentMetadata {
    static func buildExpression(_ expression: Group.RestrictedContent) -> AnyContentMetadata {
        expression
    }

    static func buildExpression(_ expression: Group) -> AnyContentMetadata {
        expression
    }

    static func buildBlock(_ components: AnyContentMetadata...) -> AnyContentMetadata {
        AnyContentMetadataArrayWrapper(components)
    }
}

