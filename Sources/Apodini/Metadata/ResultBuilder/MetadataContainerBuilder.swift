//
// Created by Andreas Bauer on 14.05.21.
//

// swiftlint:disable all
// This file was automatically generated and should not be edited.

// TODO buildIf/buildEither blocks(?)

/// The `MetadataContainerBuilder` is responsible for building `MetadataContainer`.
/// See `MetadataContainer` for more info.
@resultBuilder
public enum MetadataContainerBuilder {
    public static func buildBlock<M0: WebServiceMetadata>(_ m0: M0) -> WebServiceMetadataContainer {
        WebServiceMetadataContainer(m0)
    }
    public static func buildBlock<M0: WebServiceMetadata, M1: WebServiceMetadata>(_ m0: M0, _ m1: M1) -> WebServiceMetadataContainer {
        WebServiceMetadataContainer(TupleMetadata<(M0, M1)>((m0, m1)))
    }
    public static func buildBlock<M0: WebServiceMetadata, M1: WebServiceMetadata, M2: WebServiceMetadata>(_ m0: M0, _ m1: M1, _ m2: M2) -> WebServiceMetadataContainer {
        WebServiceMetadataContainer(TupleMetadata<(M0, M1, M2)>((m0, m1, m2)))
    }
    public static func buildBlock<M0: WebServiceMetadata, M1: WebServiceMetadata, M2: WebServiceMetadata, M3: WebServiceMetadata>(_ m0: M0, _ m1: M1, _ m2: M2, _ m3: M3) -> WebServiceMetadataContainer {
        WebServiceMetadataContainer(TupleMetadata<(M0, M1, M2, M3)>((m0, m1, m2, m3)))
    }
    public static func buildBlock<M0: WebServiceMetadata, M1: WebServiceMetadata, M2: WebServiceMetadata, M3: WebServiceMetadata, M4: WebServiceMetadata>(_ m0: M0, _ m1: M1, _ m2: M2, _ m3: M3, _ m4: M4) -> WebServiceMetadataContainer {
        WebServiceMetadataContainer(TupleMetadata<(M0, M1, M2, M3, M4)>((m0, m1, m2, m3, m4)))
    }
    public static func buildBlock<M0: WebServiceMetadata, M1: WebServiceMetadata, M2: WebServiceMetadata, M3: WebServiceMetadata, M4: WebServiceMetadata, M5: WebServiceMetadata>(_ m0: M0, _ m1: M1, _ m2: M2, _ m3: M3, _ m4: M4, _ m5: M5) -> WebServiceMetadataContainer {
        WebServiceMetadataContainer(TupleMetadata<(M0, M1, M2, M3, M4, M5)>((m0, m1, m2, m3, m4, m5)))
    }
    public static func buildBlock<M0: WebServiceMetadata, M1: WebServiceMetadata, M2: WebServiceMetadata, M3: WebServiceMetadata, M4: WebServiceMetadata, M5: WebServiceMetadata, M6: WebServiceMetadata>(_ m0: M0, _ m1: M1, _ m2: M2, _ m3: M3, _ m4: M4, _ m5: M5, _ m6: M6) -> WebServiceMetadataContainer {
        WebServiceMetadataContainer(TupleMetadata<(M0, M1, M2, M3, M4, M5, M6)>((m0, m1, m2, m3, m4, m5, m6)))
    }
    public static func buildBlock<M0: WebServiceMetadata, M1: WebServiceMetadata, M2: WebServiceMetadata, M3: WebServiceMetadata, M4: WebServiceMetadata, M5: WebServiceMetadata, M6: WebServiceMetadata, M7: WebServiceMetadata>(_ m0: M0, _ m1: M1, _ m2: M2, _ m3: M3, _ m4: M4, _ m5: M5, _ m6: M6, _ m7: M7) -> WebServiceMetadataContainer {
        WebServiceMetadataContainer(TupleMetadata<(M0, M1, M2, M3, M4, M5, M6, M7)>((m0, m1, m2, m3, m4, m5, m6, m7)))
    }
    public static func buildBlock<M0: WebServiceMetadata, M1: WebServiceMetadata, M2: WebServiceMetadata, M3: WebServiceMetadata, M4: WebServiceMetadata, M5: WebServiceMetadata, M6: WebServiceMetadata, M7: WebServiceMetadata, M8: WebServiceMetadata>(_ m0: M0, _ m1: M1, _ m2: M2, _ m3: M3, _ m4: M4, _ m5: M5, _ m6: M6, _ m7: M7, _ m8: M8) -> WebServiceMetadataContainer {
        WebServiceMetadataContainer(TupleMetadata<(M0, M1, M2, M3, M4, M5, M6, M7, M8)>((m0, m1, m2, m3, m4, m5, m6, m7, m8)))
    }
    public static func buildBlock<M0: WebServiceMetadata, M1: WebServiceMetadata, M2: WebServiceMetadata, M3: WebServiceMetadata, M4: WebServiceMetadata, M5: WebServiceMetadata, M6: WebServiceMetadata, M7: WebServiceMetadata, M8: WebServiceMetadata, M9: WebServiceMetadata>(_ m0: M0, _ m1: M1, _ m2: M2, _ m3: M3, _ m4: M4, _ m5: M5, _ m6: M6, _ m7: M7, _ m8: M8, _ m9: M9) -> WebServiceMetadataContainer {
        WebServiceMetadataContainer(TupleMetadata<(M0, M1, M2, M3, M4, M5, M6, M7, M8, M9)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9)))
    }
    public static func buildBlock<M0: WebServiceMetadata, M1: WebServiceMetadata, M2: WebServiceMetadata, M3: WebServiceMetadata, M4: WebServiceMetadata, M5: WebServiceMetadata, M6: WebServiceMetadata, M7: WebServiceMetadata, M8: WebServiceMetadata, M9: WebServiceMetadata, M10: WebServiceMetadata>(_ m0: M0, _ m1: M1, _ m2: M2, _ m3: M3, _ m4: M4, _ m5: M5, _ m6: M6, _ m7: M7, _ m8: M8, _ m9: M9, _ m10: M10) -> WebServiceMetadataContainer {
        WebServiceMetadataContainer(TupleMetadata<(M0, M1, M2, M3, M4, M5, M6, M7, M8, M9, M10)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9, m10)))
    }
    public static func buildBlock<M0: WebServiceMetadata, M1: WebServiceMetadata, M2: WebServiceMetadata, M3: WebServiceMetadata, M4: WebServiceMetadata, M5: WebServiceMetadata, M6: WebServiceMetadata, M7: WebServiceMetadata, M8: WebServiceMetadata, M9: WebServiceMetadata, M10: WebServiceMetadata, M11: WebServiceMetadata>(_ m0: M0, _ m1: M1, _ m2: M2, _ m3: M3, _ m4: M4, _ m5: M5, _ m6: M6, _ m7: M7, _ m8: M8, _ m9: M9, _ m10: M10, _ m11: M11) -> WebServiceMetadataContainer {
        WebServiceMetadataContainer(TupleMetadata<(M0, M1, M2, M3, M4, M5, M6, M7, M8, M9, M10, M11)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, m11)))
    }
    public static func buildBlock<M0: WebServiceMetadata, M1: WebServiceMetadata, M2: WebServiceMetadata, M3: WebServiceMetadata, M4: WebServiceMetadata, M5: WebServiceMetadata, M6: WebServiceMetadata, M7: WebServiceMetadata, M8: WebServiceMetadata, M9: WebServiceMetadata, M10: WebServiceMetadata, M11: WebServiceMetadata, M12: WebServiceMetadata>(_ m0: M0, _ m1: M1, _ m2: M2, _ m3: M3, _ m4: M4, _ m5: M5, _ m6: M6, _ m7: M7, _ m8: M8, _ m9: M9, _ m10: M10, _ m11: M11, _ m12: M12) -> WebServiceMetadataContainer {
        WebServiceMetadataContainer(TupleMetadata<(M0, M1, M2, M3, M4, M5, M6, M7, M8, M9, M10, M11, M12)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, m11, m12)))
    }
    public static func buildBlock<M0: WebServiceMetadata, M1: WebServiceMetadata, M2: WebServiceMetadata, M3: WebServiceMetadata, M4: WebServiceMetadata, M5: WebServiceMetadata, M6: WebServiceMetadata, M7: WebServiceMetadata, M8: WebServiceMetadata, M9: WebServiceMetadata, M10: WebServiceMetadata, M11: WebServiceMetadata, M12: WebServiceMetadata, M13: WebServiceMetadata>(_ m0: M0, _ m1: M1, _ m2: M2, _ m3: M3, _ m4: M4, _ m5: M5, _ m6: M6, _ m7: M7, _ m8: M8, _ m9: M9, _ m10: M10, _ m11: M11, _ m12: M12, _ m13: M13) -> WebServiceMetadataContainer {
        WebServiceMetadataContainer(TupleMetadata<(M0, M1, M2, M3, M4, M5, M6, M7, M8, M9, M10, M11, M12, M13)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, m11, m12, m13)))
    }
    public static func buildBlock<M0: WebServiceMetadata, M1: WebServiceMetadata, M2: WebServiceMetadata, M3: WebServiceMetadata, M4: WebServiceMetadata, M5: WebServiceMetadata, M6: WebServiceMetadata, M7: WebServiceMetadata, M8: WebServiceMetadata, M9: WebServiceMetadata, M10: WebServiceMetadata, M11: WebServiceMetadata, M12: WebServiceMetadata, M13: WebServiceMetadata, M14: WebServiceMetadata>(_ m0: M0, _ m1: M1, _ m2: M2, _ m3: M3, _ m4: M4, _ m5: M5, _ m6: M6, _ m7: M7, _ m8: M8, _ m9: M9, _ m10: M10, _ m11: M11, _ m12: M12, _ m13: M13, _ m14: M14) -> WebServiceMetadataContainer {
        WebServiceMetadataContainer(TupleMetadata<(M0, M1, M2, M3, M4, M5, M6, M7, M8, M9, M10, M11, M12, M13, M14)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, m11, m12, m13, m14)))
    }


    public static func buildBlock<M0: HandlerMetadata>(_ m0: M0) -> HandlerMetadataContainer {
        HandlerMetadataContainer(m0)
    }
    public static func buildBlock<M0: HandlerMetadata, M1: HandlerMetadata>(_ m0: M0, _ m1: M1) -> HandlerMetadataContainer {
        HandlerMetadataContainer(TupleMetadata<(M0, M1)>((m0, m1)))
    }
    public static func buildBlock<M0: HandlerMetadata, M1: HandlerMetadata, M2: HandlerMetadata>(_ m0: M0, _ m1: M1, _ m2: M2) -> HandlerMetadataContainer {
        HandlerMetadataContainer(TupleMetadata<(M0, M1, M2)>((m0, m1, m2)))
    }
    public static func buildBlock<M0: HandlerMetadata, M1: HandlerMetadata, M2: HandlerMetadata, M3: HandlerMetadata>(_ m0: M0, _ m1: M1, _ m2: M2, _ m3: M3) -> HandlerMetadataContainer {
        HandlerMetadataContainer(TupleMetadata<(M0, M1, M2, M3)>((m0, m1, m2, m3)))
    }
    public static func buildBlock<M0: HandlerMetadata, M1: HandlerMetadata, M2: HandlerMetadata, M3: HandlerMetadata, M4: HandlerMetadata>(_ m0: M0, _ m1: M1, _ m2: M2, _ m3: M3, _ m4: M4) -> HandlerMetadataContainer {
        HandlerMetadataContainer(TupleMetadata<(M0, M1, M2, M3, M4)>((m0, m1, m2, m3, m4)))
    }
    public static func buildBlock<M0: HandlerMetadata, M1: HandlerMetadata, M2: HandlerMetadata, M3: HandlerMetadata, M4: HandlerMetadata, M5: HandlerMetadata>(_ m0: M0, _ m1: M1, _ m2: M2, _ m3: M3, _ m4: M4, _ m5: M5) -> HandlerMetadataContainer {
        HandlerMetadataContainer(TupleMetadata<(M0, M1, M2, M3, M4, M5)>((m0, m1, m2, m3, m4, m5)))
    }
    public static func buildBlock<M0: HandlerMetadata, M1: HandlerMetadata, M2: HandlerMetadata, M3: HandlerMetadata, M4: HandlerMetadata, M5: HandlerMetadata, M6: HandlerMetadata>(_ m0: M0, _ m1: M1, _ m2: M2, _ m3: M3, _ m4: M4, _ m5: M5, _ m6: M6) -> HandlerMetadataContainer {
        HandlerMetadataContainer(TupleMetadata<(M0, M1, M2, M3, M4, M5, M6)>((m0, m1, m2, m3, m4, m5, m6)))
    }
    public static func buildBlock<M0: HandlerMetadata, M1: HandlerMetadata, M2: HandlerMetadata, M3: HandlerMetadata, M4: HandlerMetadata, M5: HandlerMetadata, M6: HandlerMetadata, M7: HandlerMetadata>(_ m0: M0, _ m1: M1, _ m2: M2, _ m3: M3, _ m4: M4, _ m5: M5, _ m6: M6, _ m7: M7) -> HandlerMetadataContainer {
        HandlerMetadataContainer(TupleMetadata<(M0, M1, M2, M3, M4, M5, M6, M7)>((m0, m1, m2, m3, m4, m5, m6, m7)))
    }
    public static func buildBlock<M0: HandlerMetadata, M1: HandlerMetadata, M2: HandlerMetadata, M3: HandlerMetadata, M4: HandlerMetadata, M5: HandlerMetadata, M6: HandlerMetadata, M7: HandlerMetadata, M8: HandlerMetadata>(_ m0: M0, _ m1: M1, _ m2: M2, _ m3: M3, _ m4: M4, _ m5: M5, _ m6: M6, _ m7: M7, _ m8: M8) -> HandlerMetadataContainer {
        HandlerMetadataContainer(TupleMetadata<(M0, M1, M2, M3, M4, M5, M6, M7, M8)>((m0, m1, m2, m3, m4, m5, m6, m7, m8)))
    }
    public static func buildBlock<M0: HandlerMetadata, M1: HandlerMetadata, M2: HandlerMetadata, M3: HandlerMetadata, M4: HandlerMetadata, M5: HandlerMetadata, M6: HandlerMetadata, M7: HandlerMetadata, M8: HandlerMetadata, M9: HandlerMetadata>(_ m0: M0, _ m1: M1, _ m2: M2, _ m3: M3, _ m4: M4, _ m5: M5, _ m6: M6, _ m7: M7, _ m8: M8, _ m9: M9) -> HandlerMetadataContainer {
        HandlerMetadataContainer(TupleMetadata<(M0, M1, M2, M3, M4, M5, M6, M7, M8, M9)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9)))
    }
    public static func buildBlock<M0: HandlerMetadata, M1: HandlerMetadata, M2: HandlerMetadata, M3: HandlerMetadata, M4: HandlerMetadata, M5: HandlerMetadata, M6: HandlerMetadata, M7: HandlerMetadata, M8: HandlerMetadata, M9: HandlerMetadata, M10: HandlerMetadata>(_ m0: M0, _ m1: M1, _ m2: M2, _ m3: M3, _ m4: M4, _ m5: M5, _ m6: M6, _ m7: M7, _ m8: M8, _ m9: M9, _ m10: M10) -> HandlerMetadataContainer {
        HandlerMetadataContainer(TupleMetadata<(M0, M1, M2, M3, M4, M5, M6, M7, M8, M9, M10)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9, m10)))
    }
    public static func buildBlock<M0: HandlerMetadata, M1: HandlerMetadata, M2: HandlerMetadata, M3: HandlerMetadata, M4: HandlerMetadata, M5: HandlerMetadata, M6: HandlerMetadata, M7: HandlerMetadata, M8: HandlerMetadata, M9: HandlerMetadata, M10: HandlerMetadata, M11: HandlerMetadata>(_ m0: M0, _ m1: M1, _ m2: M2, _ m3: M3, _ m4: M4, _ m5: M5, _ m6: M6, _ m7: M7, _ m8: M8, _ m9: M9, _ m10: M10, _ m11: M11) -> HandlerMetadataContainer {
        HandlerMetadataContainer(TupleMetadata<(M0, M1, M2, M3, M4, M5, M6, M7, M8, M9, M10, M11)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, m11)))
    }
    public static func buildBlock<M0: HandlerMetadata, M1: HandlerMetadata, M2: HandlerMetadata, M3: HandlerMetadata, M4: HandlerMetadata, M5: HandlerMetadata, M6: HandlerMetadata, M7: HandlerMetadata, M8: HandlerMetadata, M9: HandlerMetadata, M10: HandlerMetadata, M11: HandlerMetadata, M12: HandlerMetadata>(_ m0: M0, _ m1: M1, _ m2: M2, _ m3: M3, _ m4: M4, _ m5: M5, _ m6: M6, _ m7: M7, _ m8: M8, _ m9: M9, _ m10: M10, _ m11: M11, _ m12: M12) -> HandlerMetadataContainer {
        HandlerMetadataContainer(TupleMetadata<(M0, M1, M2, M3, M4, M5, M6, M7, M8, M9, M10, M11, M12)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, m11, m12)))
    }
    public static func buildBlock<M0: HandlerMetadata, M1: HandlerMetadata, M2: HandlerMetadata, M3: HandlerMetadata, M4: HandlerMetadata, M5: HandlerMetadata, M6: HandlerMetadata, M7: HandlerMetadata, M8: HandlerMetadata, M9: HandlerMetadata, M10: HandlerMetadata, M11: HandlerMetadata, M12: HandlerMetadata, M13: HandlerMetadata>(_ m0: M0, _ m1: M1, _ m2: M2, _ m3: M3, _ m4: M4, _ m5: M5, _ m6: M6, _ m7: M7, _ m8: M8, _ m9: M9, _ m10: M10, _ m11: M11, _ m12: M12, _ m13: M13) -> HandlerMetadataContainer {
        HandlerMetadataContainer(TupleMetadata<(M0, M1, M2, M3, M4, M5, M6, M7, M8, M9, M10, M11, M12, M13)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, m11, m12, m13)))
    }
    public static func buildBlock<M0: HandlerMetadata, M1: HandlerMetadata, M2: HandlerMetadata, M3: HandlerMetadata, M4: HandlerMetadata, M5: HandlerMetadata, M6: HandlerMetadata, M7: HandlerMetadata, M8: HandlerMetadata, M9: HandlerMetadata, M10: HandlerMetadata, M11: HandlerMetadata, M12: HandlerMetadata, M13: HandlerMetadata, M14: HandlerMetadata>(_ m0: M0, _ m1: M1, _ m2: M2, _ m3: M3, _ m4: M4, _ m5: M5, _ m6: M6, _ m7: M7, _ m8: M8, _ m9: M9, _ m10: M10, _ m11: M11, _ m12: M12, _ m13: M13, _ m14: M14) -> HandlerMetadataContainer {
        HandlerMetadataContainer(TupleMetadata<(M0, M1, M2, M3, M4, M5, M6, M7, M8, M9, M10, M11, M12, M13, M14)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, m11, m12, m13, m14)))
    }


    public static func buildBlock<M0: ComponentOnlyMetadata>(_ m0: M0) -> ComponentMetadataContainer {
        ComponentMetadataContainer(m0)
    }
    public static func buildBlock<M0: ComponentOnlyMetadata, M1: ComponentOnlyMetadata>(_ m0: M0, _ m1: M1) -> ComponentMetadataContainer {
        ComponentMetadataContainer(TupleMetadata<(M0, M1)>((m0, m1)))
    }
    public static func buildBlock<M0: ComponentOnlyMetadata, M1: ComponentOnlyMetadata, M2: ComponentOnlyMetadata>(_ m0: M0, _ m1: M1, _ m2: M2) -> ComponentMetadataContainer {
        ComponentMetadataContainer(TupleMetadata<(M0, M1, M2)>((m0, m1, m2)))
    }
    public static func buildBlock<M0: ComponentOnlyMetadata, M1: ComponentOnlyMetadata, M2: ComponentOnlyMetadata, M3: ComponentOnlyMetadata>(_ m0: M0, _ m1: M1, _ m2: M2, _ m3: M3) -> ComponentMetadataContainer {
        ComponentMetadataContainer(TupleMetadata<(M0, M1, M2, M3)>((m0, m1, m2, m3)))
    }
    public static func buildBlock<M0: ComponentOnlyMetadata, M1: ComponentOnlyMetadata, M2: ComponentOnlyMetadata, M3: ComponentOnlyMetadata, M4: ComponentOnlyMetadata>(_ m0: M0, _ m1: M1, _ m2: M2, _ m3: M3, _ m4: M4) -> ComponentMetadataContainer {
        ComponentMetadataContainer(TupleMetadata<(M0, M1, M2, M3, M4)>((m0, m1, m2, m3, m4)))
    }
    public static func buildBlock<M0: ComponentOnlyMetadata, M1: ComponentOnlyMetadata, M2: ComponentOnlyMetadata, M3: ComponentOnlyMetadata, M4: ComponentOnlyMetadata, M5: ComponentOnlyMetadata>(_ m0: M0, _ m1: M1, _ m2: M2, _ m3: M3, _ m4: M4, _ m5: M5) -> ComponentMetadataContainer {
        ComponentMetadataContainer(TupleMetadata<(M0, M1, M2, M3, M4, M5)>((m0, m1, m2, m3, m4, m5)))
    }
    public static func buildBlock<M0: ComponentOnlyMetadata, M1: ComponentOnlyMetadata, M2: ComponentOnlyMetadata, M3: ComponentOnlyMetadata, M4: ComponentOnlyMetadata, M5: ComponentOnlyMetadata, M6: ComponentOnlyMetadata>(_ m0: M0, _ m1: M1, _ m2: M2, _ m3: M3, _ m4: M4, _ m5: M5, _ m6: M6) -> ComponentMetadataContainer {
        ComponentMetadataContainer(TupleMetadata<(M0, M1, M2, M3, M4, M5, M6)>((m0, m1, m2, m3, m4, m5, m6)))
    }
    public static func buildBlock<M0: ComponentOnlyMetadata, M1: ComponentOnlyMetadata, M2: ComponentOnlyMetadata, M3: ComponentOnlyMetadata, M4: ComponentOnlyMetadata, M5: ComponentOnlyMetadata, M6: ComponentOnlyMetadata, M7: ComponentOnlyMetadata>(_ m0: M0, _ m1: M1, _ m2: M2, _ m3: M3, _ m4: M4, _ m5: M5, _ m6: M6, _ m7: M7) -> ComponentMetadataContainer {
        ComponentMetadataContainer(TupleMetadata<(M0, M1, M2, M3, M4, M5, M6, M7)>((m0, m1, m2, m3, m4, m5, m6, m7)))
    }
    public static func buildBlock<M0: ComponentOnlyMetadata, M1: ComponentOnlyMetadata, M2: ComponentOnlyMetadata, M3: ComponentOnlyMetadata, M4: ComponentOnlyMetadata, M5: ComponentOnlyMetadata, M6: ComponentOnlyMetadata, M7: ComponentOnlyMetadata, M8: ComponentOnlyMetadata>(_ m0: M0, _ m1: M1, _ m2: M2, _ m3: M3, _ m4: M4, _ m5: M5, _ m6: M6, _ m7: M7, _ m8: M8) -> ComponentMetadataContainer {
        ComponentMetadataContainer(TupleMetadata<(M0, M1, M2, M3, M4, M5, M6, M7, M8)>((m0, m1, m2, m3, m4, m5, m6, m7, m8)))
    }
    public static func buildBlock<M0: ComponentOnlyMetadata, M1: ComponentOnlyMetadata, M2: ComponentOnlyMetadata, M3: ComponentOnlyMetadata, M4: ComponentOnlyMetadata, M5: ComponentOnlyMetadata, M6: ComponentOnlyMetadata, M7: ComponentOnlyMetadata, M8: ComponentOnlyMetadata, M9: ComponentOnlyMetadata>(_ m0: M0, _ m1: M1, _ m2: M2, _ m3: M3, _ m4: M4, _ m5: M5, _ m6: M6, _ m7: M7, _ m8: M8, _ m9: M9) -> ComponentMetadataContainer {
        ComponentMetadataContainer(TupleMetadata<(M0, M1, M2, M3, M4, M5, M6, M7, M8, M9)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9)))
    }
    public static func buildBlock<M0: ComponentOnlyMetadata, M1: ComponentOnlyMetadata, M2: ComponentOnlyMetadata, M3: ComponentOnlyMetadata, M4: ComponentOnlyMetadata, M5: ComponentOnlyMetadata, M6: ComponentOnlyMetadata, M7: ComponentOnlyMetadata, M8: ComponentOnlyMetadata, M9: ComponentOnlyMetadata, M10: ComponentOnlyMetadata>(_ m0: M0, _ m1: M1, _ m2: M2, _ m3: M3, _ m4: M4, _ m5: M5, _ m6: M6, _ m7: M7, _ m8: M8, _ m9: M9, _ m10: M10) -> ComponentMetadataContainer {
        ComponentMetadataContainer(TupleMetadata<(M0, M1, M2, M3, M4, M5, M6, M7, M8, M9, M10)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9, m10)))
    }
    public static func buildBlock<M0: ComponentOnlyMetadata, M1: ComponentOnlyMetadata, M2: ComponentOnlyMetadata, M3: ComponentOnlyMetadata, M4: ComponentOnlyMetadata, M5: ComponentOnlyMetadata, M6: ComponentOnlyMetadata, M7: ComponentOnlyMetadata, M8: ComponentOnlyMetadata, M9: ComponentOnlyMetadata, M10: ComponentOnlyMetadata, M11: ComponentOnlyMetadata>(_ m0: M0, _ m1: M1, _ m2: M2, _ m3: M3, _ m4: M4, _ m5: M5, _ m6: M6, _ m7: M7, _ m8: M8, _ m9: M9, _ m10: M10, _ m11: M11) -> ComponentMetadataContainer {
        ComponentMetadataContainer(TupleMetadata<(M0, M1, M2, M3, M4, M5, M6, M7, M8, M9, M10, M11)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, m11)))
    }
    public static func buildBlock<M0: ComponentOnlyMetadata, M1: ComponentOnlyMetadata, M2: ComponentOnlyMetadata, M3: ComponentOnlyMetadata, M4: ComponentOnlyMetadata, M5: ComponentOnlyMetadata, M6: ComponentOnlyMetadata, M7: ComponentOnlyMetadata, M8: ComponentOnlyMetadata, M9: ComponentOnlyMetadata, M10: ComponentOnlyMetadata, M11: ComponentOnlyMetadata, M12: ComponentOnlyMetadata>(_ m0: M0, _ m1: M1, _ m2: M2, _ m3: M3, _ m4: M4, _ m5: M5, _ m6: M6, _ m7: M7, _ m8: M8, _ m9: M9, _ m10: M10, _ m11: M11, _ m12: M12) -> ComponentMetadataContainer {
        ComponentMetadataContainer(TupleMetadata<(M0, M1, M2, M3, M4, M5, M6, M7, M8, M9, M10, M11, M12)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, m11, m12)))
    }
    public static func buildBlock<M0: ComponentOnlyMetadata, M1: ComponentOnlyMetadata, M2: ComponentOnlyMetadata, M3: ComponentOnlyMetadata, M4: ComponentOnlyMetadata, M5: ComponentOnlyMetadata, M6: ComponentOnlyMetadata, M7: ComponentOnlyMetadata, M8: ComponentOnlyMetadata, M9: ComponentOnlyMetadata, M10: ComponentOnlyMetadata, M11: ComponentOnlyMetadata, M12: ComponentOnlyMetadata, M13: ComponentOnlyMetadata>(_ m0: M0, _ m1: M1, _ m2: M2, _ m3: M3, _ m4: M4, _ m5: M5, _ m6: M6, _ m7: M7, _ m8: M8, _ m9: M9, _ m10: M10, _ m11: M11, _ m12: M12, _ m13: M13) -> ComponentMetadataContainer {
        ComponentMetadataContainer(TupleMetadata<(M0, M1, M2, M3, M4, M5, M6, M7, M8, M9, M10, M11, M12, M13)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, m11, m12, m13)))
    }
    public static func buildBlock<M0: ComponentOnlyMetadata, M1: ComponentOnlyMetadata, M2: ComponentOnlyMetadata, M3: ComponentOnlyMetadata, M4: ComponentOnlyMetadata, M5: ComponentOnlyMetadata, M6: ComponentOnlyMetadata, M7: ComponentOnlyMetadata, M8: ComponentOnlyMetadata, M9: ComponentOnlyMetadata, M10: ComponentOnlyMetadata, M11: ComponentOnlyMetadata, M12: ComponentOnlyMetadata, M13: ComponentOnlyMetadata, M14: ComponentOnlyMetadata>(_ m0: M0, _ m1: M1, _ m2: M2, _ m3: M3, _ m4: M4, _ m5: M5, _ m6: M6, _ m7: M7, _ m8: M8, _ m9: M9, _ m10: M10, _ m11: M11, _ m12: M12, _ m13: M13, _ m14: M14) -> ComponentMetadataContainer {
        ComponentMetadataContainer(TupleMetadata<(M0, M1, M2, M3, M4, M5, M6, M7, M8, M9, M10, M11, M12, M13, M14)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, m11, m12, m13, m14)))
    }


    public static func buildBlock<M0: ContentMetadata>(_ m0: M0) -> ContentMetadataContainer {
        ContentMetadataContainer(m0)
    }
    public static func buildBlock<M0: ContentMetadata, M1: ContentMetadata>(_ m0: M0, _ m1: M1) -> ContentMetadataContainer {
        ContentMetadataContainer(TupleMetadata<(M0, M1)>((m0, m1)))
    }
    public static func buildBlock<M0: ContentMetadata, M1: ContentMetadata, M2: ContentMetadata>(_ m0: M0, _ m1: M1, _ m2: M2) -> ContentMetadataContainer {
        ContentMetadataContainer(TupleMetadata<(M0, M1, M2)>((m0, m1, m2)))
    }
    public static func buildBlock<M0: ContentMetadata, M1: ContentMetadata, M2: ContentMetadata, M3: ContentMetadata>(_ m0: M0, _ m1: M1, _ m2: M2, _ m3: M3) -> ContentMetadataContainer {
        ContentMetadataContainer(TupleMetadata<(M0, M1, M2, M3)>((m0, m1, m2, m3)))
    }
    public static func buildBlock<M0: ContentMetadata, M1: ContentMetadata, M2: ContentMetadata, M3: ContentMetadata, M4: ContentMetadata>(_ m0: M0, _ m1: M1, _ m2: M2, _ m3: M3, _ m4: M4) -> ContentMetadataContainer {
        ContentMetadataContainer(TupleMetadata<(M0, M1, M2, M3, M4)>((m0, m1, m2, m3, m4)))
    }
    public static func buildBlock<M0: ContentMetadata, M1: ContentMetadata, M2: ContentMetadata, M3: ContentMetadata, M4: ContentMetadata, M5: ContentMetadata>(_ m0: M0, _ m1: M1, _ m2: M2, _ m3: M3, _ m4: M4, _ m5: M5) -> ContentMetadataContainer {
        ContentMetadataContainer(TupleMetadata<(M0, M1, M2, M3, M4, M5)>((m0, m1, m2, m3, m4, m5)))
    }
    public static func buildBlock<M0: ContentMetadata, M1: ContentMetadata, M2: ContentMetadata, M3: ContentMetadata, M4: ContentMetadata, M5: ContentMetadata, M6: ContentMetadata>(_ m0: M0, _ m1: M1, _ m2: M2, _ m3: M3, _ m4: M4, _ m5: M5, _ m6: M6) -> ContentMetadataContainer {
        ContentMetadataContainer(TupleMetadata<(M0, M1, M2, M3, M4, M5, M6)>((m0, m1, m2, m3, m4, m5, m6)))
    }
    public static func buildBlock<M0: ContentMetadata, M1: ContentMetadata, M2: ContentMetadata, M3: ContentMetadata, M4: ContentMetadata, M5: ContentMetadata, M6: ContentMetadata, M7: ContentMetadata>(_ m0: M0, _ m1: M1, _ m2: M2, _ m3: M3, _ m4: M4, _ m5: M5, _ m6: M6, _ m7: M7) -> ContentMetadataContainer {
        ContentMetadataContainer(TupleMetadata<(M0, M1, M2, M3, M4, M5, M6, M7)>((m0, m1, m2, m3, m4, m5, m6, m7)))
    }
    public static func buildBlock<M0: ContentMetadata, M1: ContentMetadata, M2: ContentMetadata, M3: ContentMetadata, M4: ContentMetadata, M5: ContentMetadata, M6: ContentMetadata, M7: ContentMetadata, M8: ContentMetadata>(_ m0: M0, _ m1: M1, _ m2: M2, _ m3: M3, _ m4: M4, _ m5: M5, _ m6: M6, _ m7: M7, _ m8: M8) -> ContentMetadataContainer {
        ContentMetadataContainer(TupleMetadata<(M0, M1, M2, M3, M4, M5, M6, M7, M8)>((m0, m1, m2, m3, m4, m5, m6, m7, m8)))
    }
    public static func buildBlock<M0: ContentMetadata, M1: ContentMetadata, M2: ContentMetadata, M3: ContentMetadata, M4: ContentMetadata, M5: ContentMetadata, M6: ContentMetadata, M7: ContentMetadata, M8: ContentMetadata, M9: ContentMetadata>(_ m0: M0, _ m1: M1, _ m2: M2, _ m3: M3, _ m4: M4, _ m5: M5, _ m6: M6, _ m7: M7, _ m8: M8, _ m9: M9) -> ContentMetadataContainer {
        ContentMetadataContainer(TupleMetadata<(M0, M1, M2, M3, M4, M5, M6, M7, M8, M9)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9)))
    }
    public static func buildBlock<M0: ContentMetadata, M1: ContentMetadata, M2: ContentMetadata, M3: ContentMetadata, M4: ContentMetadata, M5: ContentMetadata, M6: ContentMetadata, M7: ContentMetadata, M8: ContentMetadata, M9: ContentMetadata, M10: ContentMetadata>(_ m0: M0, _ m1: M1, _ m2: M2, _ m3: M3, _ m4: M4, _ m5: M5, _ m6: M6, _ m7: M7, _ m8: M8, _ m9: M9, _ m10: M10) -> ContentMetadataContainer {
        ContentMetadataContainer(TupleMetadata<(M0, M1, M2, M3, M4, M5, M6, M7, M8, M9, M10)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9, m10)))
    }
    public static func buildBlock<M0: ContentMetadata, M1: ContentMetadata, M2: ContentMetadata, M3: ContentMetadata, M4: ContentMetadata, M5: ContentMetadata, M6: ContentMetadata, M7: ContentMetadata, M8: ContentMetadata, M9: ContentMetadata, M10: ContentMetadata, M11: ContentMetadata>(_ m0: M0, _ m1: M1, _ m2: M2, _ m3: M3, _ m4: M4, _ m5: M5, _ m6: M6, _ m7: M7, _ m8: M8, _ m9: M9, _ m10: M10, _ m11: M11) -> ContentMetadataContainer {
        ContentMetadataContainer(TupleMetadata<(M0, M1, M2, M3, M4, M5, M6, M7, M8, M9, M10, M11)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, m11)))
    }
    public static func buildBlock<M0: ContentMetadata, M1: ContentMetadata, M2: ContentMetadata, M3: ContentMetadata, M4: ContentMetadata, M5: ContentMetadata, M6: ContentMetadata, M7: ContentMetadata, M8: ContentMetadata, M9: ContentMetadata, M10: ContentMetadata, M11: ContentMetadata, M12: ContentMetadata>(_ m0: M0, _ m1: M1, _ m2: M2, _ m3: M3, _ m4: M4, _ m5: M5, _ m6: M6, _ m7: M7, _ m8: M8, _ m9: M9, _ m10: M10, _ m11: M11, _ m12: M12) -> ContentMetadataContainer {
        ContentMetadataContainer(TupleMetadata<(M0, M1, M2, M3, M4, M5, M6, M7, M8, M9, M10, M11, M12)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, m11, m12)))
    }
    public static func buildBlock<M0: ContentMetadata, M1: ContentMetadata, M2: ContentMetadata, M3: ContentMetadata, M4: ContentMetadata, M5: ContentMetadata, M6: ContentMetadata, M7: ContentMetadata, M8: ContentMetadata, M9: ContentMetadata, M10: ContentMetadata, M11: ContentMetadata, M12: ContentMetadata, M13: ContentMetadata>(_ m0: M0, _ m1: M1, _ m2: M2, _ m3: M3, _ m4: M4, _ m5: M5, _ m6: M6, _ m7: M7, _ m8: M8, _ m9: M9, _ m10: M10, _ m11: M11, _ m12: M12, _ m13: M13) -> ContentMetadataContainer {
        ContentMetadataContainer(TupleMetadata<(M0, M1, M2, M3, M4, M5, M6, M7, M8, M9, M10, M11, M12, M13)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, m11, m12, m13)))
    }
    public static func buildBlock<M0: ContentMetadata, M1: ContentMetadata, M2: ContentMetadata, M3: ContentMetadata, M4: ContentMetadata, M5: ContentMetadata, M6: ContentMetadata, M7: ContentMetadata, M8: ContentMetadata, M9: ContentMetadata, M10: ContentMetadata, M11: ContentMetadata, M12: ContentMetadata, M13: ContentMetadata, M14: ContentMetadata>(_ m0: M0, _ m1: M1, _ m2: M2, _ m3: M3, _ m4: M4, _ m5: M5, _ m6: M6, _ m7: M7, _ m8: M8, _ m9: M9, _ m10: M10, _ m11: M11, _ m12: M12, _ m13: M13, _ m14: M14) -> ContentMetadataContainer {
        ContentMetadataContainer(TupleMetadata<(M0, M1, M2, M3, M4, M5, M6, M7, M8, M9, M10, M11, M12, M13, M14)>((m0, m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, m11, m12, m13, m14)))
    }
}
