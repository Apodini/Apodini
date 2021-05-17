//
// Created by Andreas Bauer on 16.05.21.
//

// swiftlint:disable all
// This file was automatically generated and should not be edited.

/// The `CustomMetadataGroupBuilder` is responsible for building `CustomMetadataGroup`s.
/// See `CustomMetadataGroup` for more info.
@resultBuilder
public enum CustomMetadataGroupBuilder<Group: CustomMetadataGroup, Content: AnyMetadata> {
    public static func buildBlock(_ m0: Content) -> Content {
        m0
    }

    public static func buildBlock(_ g0: Group) -> Group {
        g0
    }

    public static func buildBlock(_ m0: Content, _ m1: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content)>((m0, m1))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group)>((m0, m1))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content)>((m0, m1))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group)>((m0, m1))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content)>((m0, m1, m2))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group)>((m0, m1, m2))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content)>((m0, m1, m2))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content)>((m0, m1, m2))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group)>((m0, m1, m2))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group)>((m0, m1, m2))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content)>((m0, m1, m2))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group)>((m0, m1, m2))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content)>((m0, m1, m2, m3))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group)>((m0, m1, m2, m3))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content)>((m0, m1, m2, m3))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content)>((m0, m1, m2, m3))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content)>((m0, m1, m2, m3))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group)>((m0, m1, m2, m3))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group)>((m0, m1, m2, m3))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content)>((m0, m1, m2, m3))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group)>((m0, m1, m2, m3))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content)>((m0, m1, m2, m3))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content)>((m0, m1, m2, m3))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group)>((m0, m1, m2, m3))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group)>((m0, m1, m2, m3))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group)>((m0, m1, m2, m3))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content)>((m0, m1, m2, m3))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group)>((m0, m1, m2, m3))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Content)>((m0, m1, m2, m3, m4))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Group)>((m0, m1, m2, m3, m4))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Content)>((m0, m1, m2, m3, m4))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Content)>((m0, m1, m2, m3, m4))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Content)>((m0, m1, m2, m3, m4))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Content)>((m0, m1, m2, m3, m4))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Group)>((m0, m1, m2, m3, m4))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Group)>((m0, m1, m2, m3, m4))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Content)>((m0, m1, m2, m3, m4))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Group)>((m0, m1, m2, m3, m4))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Content)>((m0, m1, m2, m3, m4))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Content)>((m0, m1, m2, m3, m4))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Group)>((m0, m1, m2, m3, m4))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Content)>((m0, m1, m2, m3, m4))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Content)>((m0, m1, m2, m3, m4))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Content)>((m0, m1, m2, m3, m4))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Group)>((m0, m1, m2, m3, m4))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Group)>((m0, m1, m2, m3, m4))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Group)>((m0, m1, m2, m3, m4))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Content)>((m0, m1, m2, m3, m4))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Group)>((m0, m1, m2, m3, m4))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Group)>((m0, m1, m2, m3, m4))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Content)>((m0, m1, m2, m3, m4))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Group)>((m0, m1, m2, m3, m4))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Content)>((m0, m1, m2, m3, m4))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Content)>((m0, m1, m2, m3, m4))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Group)>((m0, m1, m2, m3, m4))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Group)>((m0, m1, m2, m3, m4))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Group)>((m0, m1, m2, m3, m4))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Group)>((m0, m1, m2, m3, m4))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Content)>((m0, m1, m2, m3, m4))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Group)>((m0, m1, m2, m3, m4))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Content, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Content, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Content, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Content, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Content, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Group, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Content, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Content, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Content, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Content, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Content, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Content, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Content, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Content, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Content, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Content, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Group, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Group, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Group, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Group, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Content, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Content, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Content, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Content, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Group, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Content, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Content, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Content, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Content, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Group, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Content, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Content, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Content, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Content, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Content, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Group, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Content, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Content, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Content, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Content, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Content, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Content, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Group, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Content, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Content, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Content, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Content, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Content, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Content, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Content, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Group, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Group, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Group, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Group, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Group, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Group, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Content, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Content, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Content, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Content, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Content, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Content, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Group, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Group, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Group, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Group, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Content, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Content, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Content, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Content, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Content, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Content, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Group, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Group, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Group, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Group, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Content, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Content, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Content, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Content, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Group, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Content, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Content, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Content, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Content, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Content, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Content, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Group, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Group, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Group, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Group, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Content, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Content, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Content, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Content, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Group, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Content, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Content, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Content, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Content, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Group, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Content, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Content, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Content, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Content, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Content, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Content, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Content, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Group, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Group, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Group, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Group, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Content, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Content, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Content, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Content, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Group, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Content, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Content, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Content, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Content, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Group, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Content, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Content, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Content, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Content, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Content, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Group, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Content, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Content, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Content, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Group, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Group, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Group, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Group, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Content, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Content, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Content, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Content, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Group, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Group, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Group, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Group, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Group, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Group, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Content, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Content, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Content, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Content, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Group, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Group, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Group, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Group, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Group, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Group, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Content, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Content, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Content, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Content, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Content, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Content, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Group, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Group, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Group, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Group, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Content, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Content, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Content, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Content, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Group, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Group, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Group, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Group, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Group, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Group, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Content, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Content, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Content, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Content, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Content, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Content, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Group, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Group, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Group, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Group, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Content, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Content, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Content, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Content, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Content, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Content, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Group, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Group, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Group, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Group, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Content, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Content, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Content, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Content, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Group, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Content, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Content, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Content, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Content, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Group, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Group, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Group, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Group, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Group, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Group, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Content, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Content, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Content, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Content, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Content, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Content, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Group, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Group, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Group, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Group, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Content, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Content, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Content, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Content, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Content, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Content, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Group, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Group, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Group, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Group, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Content, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Content, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Content, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Content, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Group, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Content, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Content, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Content, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Content, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Content, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Content, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Group, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Group, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Group, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Group, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Content, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Content, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Content, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Content, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Group, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Content, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Content, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Content, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Content, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Group, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Content, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Group, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Content, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Group, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Group, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Group, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Group, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Content, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Group, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Group, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Group, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Group, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Content, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Content, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Content, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Content, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Group, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Group, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Group, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Group, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Group, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Group, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Content, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Group, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Group, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Group, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Group, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Content, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Content, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Content, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Content, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Group, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Group, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Group, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Group, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Group, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Group, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Content, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Content, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Content, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Content, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Group, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Group, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Group, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Group, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Group, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Group, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Content, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Content, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Content, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Content, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Content, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Content, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Group, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Group, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Group, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Group, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Content, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Group, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Group, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Group, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Group, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Content, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Content, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Content, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Content, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Group, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Group, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Group, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Group, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Group, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Group, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Content, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Content, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Content, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Content, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Group, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Group, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Group, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Group, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Group, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Group, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Content, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Content, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Content, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Content, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Content, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Content, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Group, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Group, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Group, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Group, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Content, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Content, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Content, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Content, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Group, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Group, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Group, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Group, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Group, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Group, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Content, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Content, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Content, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Content, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Content, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Content, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Group, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Group, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Group, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Group, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Content, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Content, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Content, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Content, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Content, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Content, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Group, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Group, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Group, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Group, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Content, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Content, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Content, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Content, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Group, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Group, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Group, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Content, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Group, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Group, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Group, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Group, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Group, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Content, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Group, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Group, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Group, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Group, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Content, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Group, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Group, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Group, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Group, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Content, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Content, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Content, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Content, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Group, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Group, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Group, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Group, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Group, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Group, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Group, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Content, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Group, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Group, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Group, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Group, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Content, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Group, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Group, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Group, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Group, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Content, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Content, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Content, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Content, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Group, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Group, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Group, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Group, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Group, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Group, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Content, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Group, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Group, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Group, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Group, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Content, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Content, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Content, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Content, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Group, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Group, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Group, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Group, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Group, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Group, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Content, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Content, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Content, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Content, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Group, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Group, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Group, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Group, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Group, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Group, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Content, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Content, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Content, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Content, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Content, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Content, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Group, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Group, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Group, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Group, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Group, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Group, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Group, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Content, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Group, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Group, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Group, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Group, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Group, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Group, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Content, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Group, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Group, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Group, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Group, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Group, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Content, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Group, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Group, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Group, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Group, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Content, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Group, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Group, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Group, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Group, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Content, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Content, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Content, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Content, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Group, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Group, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Group, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Group, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Group, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Group, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Group, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Group, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Group, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Group, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Content, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Group, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Group, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Group, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Group, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Group, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Content, Content, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Content, Content, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Content, Content, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Content, Content, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Content, Content, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Content, Group, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Group, Content, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Content, Content, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Content, Content, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Content, Content, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Content, Content, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Content, Content, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Content, Content, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Content, Content, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Content, Content, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Content, Content, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Content, Content, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Content, Group, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Content, Group, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Content, Group, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Content, Group, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Group, Content, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Group, Content, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Group, Content, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Group, Content, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Group, Group, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Content, Content, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Content, Content, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Content, Content, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Content, Content, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Content, Group, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Group, Content, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Content, Content, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Content, Content, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Content, Content, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Content, Content, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Content, Group, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Group, Content, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Content, Content, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Content, Content, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Content, Content, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Content, Content, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Content, Content, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Content, Group, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Group, Content, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Content, Content, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Content, Content, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Content, Content, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Content, Content, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Content, Content, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Content, Content, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Content, Group, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Group, Content, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Content, Content, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Content, Content, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Content, Content, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Content, Content, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Content, Content, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Content, Content, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Content, Content, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Content, Group, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Content, Group, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Content, Group, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Content, Group, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Content, Group, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Content, Group, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Group, Content, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Group, Content, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Group, Content, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Group, Content, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Group, Content, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Group, Content, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Group, Group, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Group, Group, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Group, Group, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Group, Group, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Content, Content, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Content, Content, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Content, Content, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Content, Content, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Content, Content, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Content, Content, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Content, Group, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Content, Group, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Content, Group, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Content, Group, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Group, Content, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Group, Content, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Group, Content, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Group, Content, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Group, Group, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Content, Content, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Content, Content, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Content, Content, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Content, Content, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Content, Content, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Content, Content, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Content, Group, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Content, Group, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Content, Group, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Content, Group, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Group, Content, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Group, Content, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Group, Content, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Group, Content, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Group, Group, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Content, Content, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Content, Content, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Content, Content, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Content, Content, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Content, Group, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Group, Content, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Content, Content, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Content, Content, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Content, Content, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Content, Content, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Content, Content, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Content, Content, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Content, Group, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Content, Group, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Content, Group, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Content, Group, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Group, Content, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Group, Content, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Group, Content, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Group, Content, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Group, Group, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Content, Content, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Content, Content, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Content, Content, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Content, Content, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Content, Group, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Group, Content, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Content, Content, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Content, Content, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Content, Content, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Content, Content, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Content, Group, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Group, Content, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Content, Content, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Content, Content, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Content, Content, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Content, Content, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Content, Content, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Content, Content, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Content, Content, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Content, Group, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Content, Group, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Content, Group, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Content, Group, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Group, Content, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Group, Content, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Group, Content, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Group, Content, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Group, Group, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Content, Content, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Content, Content, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Content, Content, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Content, Content, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Content, Group, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Group, Content, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Content, Content, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Content, Content, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Content, Content, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Content, Content, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Content, Group, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Group, Content, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Content, Content, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Content, Content, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Content, Content, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Content, Content, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Content, Content, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Content, Group, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Group, Content, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Content, Content, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Content, Content, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Content, Content, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Content, Group, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Content, Group, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Content, Group, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Content, Group, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Group, Content, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Group, Content, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Group, Content, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Group, Content, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Group, Group, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Group, Group, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Group, Group, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Group, Group, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Group, Group, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Group, Group, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Content, Content, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Content, Content, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Content, Content, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Content, Content, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Content, Group, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Content, Group, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Content, Group, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Content, Group, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Content, Group, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Content, Group, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Group, Content, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Group, Content, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Group, Content, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Group, Content, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Group, Content, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Group, Content, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Group, Group, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Group, Group, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Group, Group, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Group, Group, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Content, Content, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Content, Content, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Content, Content, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Content, Content, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Content, Group, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Content, Group, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Content, Group, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Content, Group, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Content, Group, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Content, Group, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Group, Content, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Group, Content, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Group, Content, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Group, Content, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Group, Content, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Group, Content, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Group, Group, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Group, Group, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Group, Group, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Group, Group, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Content, Content, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Content, Content, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Content, Content, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Content, Content, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Content, Content, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Content, Content, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Content, Group, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Content, Group, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Content, Group, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Content, Group, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Group, Content, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Group, Content, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Group, Content, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Group, Content, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Group, Group, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Content, Content, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Content, Content, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Content, Content, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Content, Content, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Content, Group, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Content, Group, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Content, Group, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Content, Group, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Content, Group, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Content, Group, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Group, Content, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Group, Content, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Group, Content, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Group, Content, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Group, Content, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Group, Content, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Group, Group, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Group, Group, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Group, Group, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Group, Group, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Content, Content, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Content, Content, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Content, Content, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Content, Content, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Content, Content, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Content, Content, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Content, Group, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Content, Group, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Content, Group, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Content, Group, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Group, Content, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Group, Content, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Group, Content, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Group, Content, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Group, Group, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Content, Content, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Content, Content, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Content, Content, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Content, Content, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Content, Content, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Content, Content, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Content, Group, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Content, Group, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Content, Group, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Content, Group, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Group, Content, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Group, Content, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Group, Content, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Group, Content, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Group, Group, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Content, Content, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Content, Content, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Content, Content, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Content, Content, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Content, Group, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Group, Content, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Content, Content, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Content, Content, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Content, Content, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Content, Content, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Content, Group, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Content, Group, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Content, Group, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Content, Group, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Content, Group, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Content, Group, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Group, Content, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Group, Content, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Group, Content, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Group, Content, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Group, Content, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Group, Content, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Group, Group, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Group, Group, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Group, Group, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Group, Group, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Content, Content, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Content, Content, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Content, Content, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Content, Content, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Content, Content, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Content, Content, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Content, Group, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Content, Group, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Content, Group, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Content, Group, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Group, Content, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Group, Content, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Group, Content, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Group, Content, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Group, Group, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Content, Content, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Content, Content, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Content, Content, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Content, Content, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Content, Content, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Content, Content, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Content, Group, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Content, Group, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Content, Group, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Content, Group, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Group, Content, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Group, Content, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Group, Content, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Group, Content, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Group, Group, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Content, Content, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Content, Content, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Content, Content, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Content, Content, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Content, Group, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Group, Content, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Content, Content, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Content, Content, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Content, Content, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Content, Content, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Content, Content, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Content, Content, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Content, Group, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Content, Group, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Content, Group, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Content, Group, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Group, Content, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Group, Content, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Group, Content, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Group, Content, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Group, Group, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Content, Content, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Content, Content, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Content, Content, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Content, Content, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Content, Group, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Group, Content, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Content, Content, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Content, Content, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Content, Content, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Content, Content, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Content, Group, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Group, Content, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Content, Content, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Content, Group, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Group, Content, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Group, Group, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Group, Group, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Group, Group, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Group, Group, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Content, Content, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Content, Group, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Content, Group, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Content, Group, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Content, Group, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Group, Content, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Group, Content, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Group, Content, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Group, Content, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Group, Group, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Group, Group, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Group, Group, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Group, Group, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Group, Group, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Group, Group, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Content, Content, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Content, Group, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Content, Group, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Content, Group, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Content, Group, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Group, Content, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Group, Content, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Group, Content, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Group, Content, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Group, Group, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Group, Group, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Group, Group, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Group, Group, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Group, Group, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Group, Group, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Content, Content, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Content, Content, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Content, Content, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Content, Content, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Content, Group, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Content, Group, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Content, Group, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Content, Group, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Content, Group, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Content, Group, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Group, Content, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Group, Content, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Group, Content, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Group, Content, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Group, Content, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Group, Content, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Group, Group, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Group, Group, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Group, Group, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Group, Group, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Content, Content, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Content, Group, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Content, Group, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Content, Group, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Content, Group, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Group, Content, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Group, Content, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Group, Content, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Group, Content, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Group, Group, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Group, Group, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Group, Group, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Group, Group, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Group, Group, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Group, Group, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Content, Content, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Content, Content, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Content, Content, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Content, Content, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Content, Group, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Content, Group, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Content, Group, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Content, Group, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Content, Group, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Content, Group, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Group, Content, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Group, Content, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Group, Content, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Group, Content, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Group, Content, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Group, Content, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Group, Group, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Group, Group, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Group, Group, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Group, Group, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Content, Content, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Content, Content, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Content, Content, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Content, Content, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Content, Group, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Content, Group, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Content, Group, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Content, Group, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Content, Group, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Content, Group, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Group, Content, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Group, Content, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Group, Content, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Group, Content, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Group, Content, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Group, Content, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Group, Group, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Group, Group, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Group, Group, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Group, Group, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Content, Content, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Content, Content, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Content, Content, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Content, Content, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Content, Content, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Content, Content, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Content, Group, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Content, Group, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Content, Group, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Content, Group, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Group, Content, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Group, Content, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Group, Content, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Group, Content, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Group, Group, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Content, Content, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Content, Group, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Content, Group, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Content, Group, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Content, Group, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Group, Content, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Group, Content, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Group, Content, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Group, Content, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Group, Group, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Group, Group, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Group, Group, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Group, Group, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Group, Group, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Group, Group, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Content, Content, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Content, Content, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Content, Content, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Content, Content, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Content, Group, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Content, Group, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Content, Group, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Content, Group, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Content, Group, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Content, Group, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Group, Content, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Group, Content, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Group, Content, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Group, Content, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Group, Content, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Group, Content, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Group, Group, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Group, Group, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Group, Group, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Group, Group, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Content, Content, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Content, Content, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Content, Content, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Content, Content, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Content, Group, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Content, Group, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Content, Group, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Content, Group, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Content, Group, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Content, Group, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Group, Content, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Group, Content, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Group, Content, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Group, Content, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Group, Content, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Group, Content, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Group, Group, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Group, Group, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Group, Group, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Group, Group, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Content, Content, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Content, Content, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Content, Content, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Content, Content, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Content, Content, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Content, Content, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Content, Group, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Content, Group, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Content, Group, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Content, Group, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Group, Content, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Group, Content, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Group, Content, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Group, Content, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Group, Group, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Content, Content, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Content, Content, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Content, Content, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Content, Content, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Content, Group, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Content, Group, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Content, Group, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Content, Group, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Content, Group, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Content, Group, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Group, Content, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Group, Content, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Group, Content, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Group, Content, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Group, Content, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Group, Content, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Group, Group, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Group, Group, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Group, Group, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Group, Group, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Content, Content, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Content, Content, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Content, Content, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Content, Content, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Content, Content, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Content, Content, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Content, Group, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Content, Group, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Content, Group, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Content, Group, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Group, Content, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Group, Content, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Group, Content, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Group, Content, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Group, Group, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Content, Content, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Content, Content, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Content, Content, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Content, Content, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Content, Content, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Content, Content, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Content, Group, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Content, Group, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Content, Group, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Content, Group, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Group, Content, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Group, Content, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Group, Content, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Group, Content, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Group, Group, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Content, Content, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Content, Content, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Content, Content, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Content, Content, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Content, Group, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Group, Content, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Content, Group, Group, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Content, Group, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Group, Content, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Group, Group, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Group, Group, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Group, Group, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Group, Group, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Content, Group, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Group, Content, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Group, Group, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Group, Group, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Group, Group, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Group, Group, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Content, Content, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Content, Group, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Content, Group, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Content, Group, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Content, Group, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Group, Content, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Group, Content, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Group, Content, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Group, Content, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Group, Group, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Group, Group, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Group, Group, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Group, Group, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Group, Group, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Group, Group, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Content, Group, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Group, Content, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Group, Group, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Group, Group, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Group, Group, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Group, Group, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Content, Content, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Content, Group, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Content, Group, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Content, Group, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Content, Group, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Group, Content, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Group, Content, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Group, Content, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Group, Content, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Group, Group, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Group, Group, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Group, Group, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Group, Group, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Group, Group, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Group, Group, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Content, Content, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Content, Group, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Content, Group, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Content, Group, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Content, Group, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Group, Content, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Group, Content, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Group, Content, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Group, Content, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Group, Group, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Group, Group, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Group, Group, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Group, Group, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Group, Group, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Group, Group, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Content, Content, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Content, Content, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Content, Content, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Content, Content, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Content, Group, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Content, Group, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Content, Group, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Content, Group, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Content, Group, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Content, Group, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Group, Content, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Group, Content, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Group, Content, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Group, Content, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Group, Content, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Group, Content, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Group, Group, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Group, Group, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Group, Group, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Group, Group, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Content, Group, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Group, Content, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Group, Group, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Group, Group, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Group, Group, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Group, Group, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Content, Content, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Content, Group, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Content, Group, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Content, Group, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Content, Group, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Group, Content, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Group, Content, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Group, Content, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Group, Content, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Group, Group, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Group, Group, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Group, Group, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Group, Group, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Group, Group, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Group, Group, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Content, Content, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Content, Group, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Content, Group, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Content, Group, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Content, Group, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Group, Content, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Group, Content, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Group, Content, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Group, Content, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Group, Group, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Group, Group, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Group, Group, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Group, Group, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Group, Group, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Group, Group, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Content, Content, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Content, Content, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Content, Content, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Content, Content, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Content, Group, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Content, Group, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Content, Group, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Content, Group, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Content, Group, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Content, Group, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Group, Content, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Group, Content, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Group, Content, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Group, Content, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Group, Content, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Group, Content, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Group, Group, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Group, Group, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Group, Group, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Group, Group, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Content, Content, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Content, Group, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Content, Group, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Content, Group, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Content, Group, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Group, Content, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Group, Content, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Group, Content, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Group, Content, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Group, Group, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Group, Group, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Group, Group, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Group, Group, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Group, Group, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Group, Group, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Content, Content, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Content, Content, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Content, Content, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Content, Content, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Content, Group, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Content, Group, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Content, Group, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Content, Group, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Content, Group, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Content, Group, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Group, Content, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Group, Content, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Group, Content, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Group, Content, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Group, Content, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Group, Content, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Group, Group, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Group, Group, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Group, Group, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Group, Group, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Content, Content, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Content, Content, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Content, Content, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Content, Content, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Content, Group, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Content, Group, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Content, Group, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Content, Group, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Content, Group, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Content, Group, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Group, Content, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Group, Content, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Group, Content, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Group, Content, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Group, Content, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Group, Content, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Group, Group, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Group, Group, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Group, Group, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Group, Group, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Content, Content, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Content, Content, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Content, Content, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Content, Content, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Content, Content, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Content, Content, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Content, Group, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Content, Group, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Content, Group, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Content, Group, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Group, Content, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Group, Content, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Group, Content, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Group, Content, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Group, Group, Content, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Content, Group, Group, Group, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Content, Group, Group, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Content, Group, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Group, Content, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Group, Group, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Group, Group, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Group, Group, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Group, Group, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Content, Group, Group, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Content, Group, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Group, Content, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Group, Group, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Group, Group, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Group, Group, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Group, Group, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Content, Group, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Group, Content, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Group, Group, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Group, Group, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Group, Group, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Group, Group, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Content, Content, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Content, Group, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Content, Group, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Content, Group, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Content, Group, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Group, Content, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Group, Content, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Group, Content, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Group, Content, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Group, Group, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Group, Group, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Group, Group, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Group, Group, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Group, Group, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Group, Group, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Content, Group, Group, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Content, Group, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Group, Content, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Group, Group, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Group, Group, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Group, Group, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Group, Group, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Content, Group, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Group, Content, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Group, Group, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Group, Group, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Group, Group, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Group, Group, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Content, Content, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Content, Group, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Content, Group, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Content, Group, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Content, Group, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Group, Content, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Group, Content, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Group, Content, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Group, Content, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Group, Group, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Group, Group, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Group, Group, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Group, Group, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Group, Group, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Group, Group, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Content, Group, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Group, Content, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Group, Group, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Group, Group, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Group, Group, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Group, Group, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Content, Content, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Content, Group, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Content, Group, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Content, Group, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Content, Group, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Group, Content, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Group, Content, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Group, Content, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Group, Content, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Group, Group, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Group, Group, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Group, Group, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Group, Group, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Group, Group, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Group, Group, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Content, Content, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Content, Group, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Content, Group, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Content, Group, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Content, Group, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Group, Content, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Group, Content, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Group, Content, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Group, Content, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Group, Group, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Group, Group, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Group, Group, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Group, Group, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Group, Group, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Group, Group, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Content, Content, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Content, Content, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Content, Content, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Content, Content, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Content, Group, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Content, Group, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Content, Group, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Content, Group, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Content, Group, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Content, Group, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Group, Content, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Group, Content, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Group, Content, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Group, Content, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Group, Content, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Group, Content, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Group, Group, Content, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Group, Group, Content, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Group, Group, Content, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Group, Group, Group, Content, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Content, Group, Group, Group, Group, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Content, Group, Group, Group, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Content, Group, Group, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Content, Group, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Group, Content, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Group, Group, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Group, Group, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Group, Group, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Group, Group, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Content, Group, Group, Group, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Content, Group, Group, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Content, Group, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Group, Content, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Group, Group, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Group, Group, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Group, Group, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Group, Group, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Content, Group, Group, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Content, Group, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Group, Content, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Group, Group, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Group, Group, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Group, Group, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Group, Group, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Content, Group, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Group, Content, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Group, Group, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Group, Group, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Group, Group, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Group, Group, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Content, Content, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Content, Group, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Content, Group, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Content, Group, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Content, Group, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Group, Content, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Group, Content, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Group, Content, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Group, Content, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Group, Group, Content, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Group, Group, Content, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Group, Group, Content, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Group, Group, Group, Content, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Group, Group, Group, Content, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Group, Group, Group, Group, Content, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Content, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Content, Group, Group, Group, Group, Group, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Content, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Content, Group, Group, Group, Group, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Content, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Content, Group, Group, Group, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Content, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Content, Group, Group, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Content, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Content, Group, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Content, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Group, Content, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Content, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Group, Group, Content, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Content, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Group, Group, Group, Content, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Content, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Group, Group, Group, Group, Content, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Content) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Group, Group, Group, Group, Group, Content)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }

    public static func buildBlock(_ m0: Group, _ m1: Group, _ m2: Group, _ m3: Group, _ m4: Group, _ m5: Group, _ m6: Group, _ m7: Group, _ m8: Group, _ m9: Group) -> AnyMetadata {
        TupleMetadata<(Group, Group, Group, Group, Group, Group, Group, Group, Group, Group)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9))
    }
}
