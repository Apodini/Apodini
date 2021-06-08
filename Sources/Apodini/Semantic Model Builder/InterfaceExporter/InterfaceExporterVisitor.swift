//
// Created by Andreas Bauer on 30.01.21.
//

import NIO
@_implementationOnly import AssociatedTypeRequirementsVisitor

protocol InterfaceExporterVisitor {
    func visit<I: InterfaceExporter>(exporter: I)
    func visit<I: StaticInterfaceExporter>(staticExporter: I)
}

protocol ExporterVisitable {
    func accept(_ visitor: InterfaceExporterVisitor)
}


struct AnyInterfaceExporter {
    private let accept: (_ visitor: InterfaceExporterVisitor) -> Void

    init<I: BaseInterfaceExporter>(_ exporter: I) {
        let exporterVisitor = StandardExporterVisitableVisitor()
        if let accept = exporterVisitor(exporter) {
            self.accept = accept
        } else {
            let staticVisitor = StandardStaticExporterVisitableVisitor()
            guard let accept = staticVisitor(exporter) else {
                fatalError("Encountered an illegally defined InterfaceExporter: \(I.self)")
            }
            self.accept = accept
        }
    }

    func accept(_ visitor: InterfaceExporterVisitor) {
        accept(visitor)
    }
}

extension Array where Element == AnyInterfaceExporter {
    func acceptAll(_ visitor: InterfaceExporterVisitor) {
        for exporter in self {
            exporter.accept(visitor)
        }
    }
}

private protocol ExporterVisitableVisitor: AssociatedTypeRequirementsVisitor {
    associatedtype Visitor = ExporterVisitableVisitor
    associatedtype Input = InterfaceExporter
    associatedtype Output

    func callAsFunction<I: InterfaceExporter>(_ value: I) -> Output
}

private struct StandardExporterVisitableVisitor: ExporterVisitableVisitor {
    func callAsFunction<I: InterfaceExporter>(_ value: I) -> (_ visitor: InterfaceExporterVisitor) -> Void {
        value.accept
    }
}

private protocol StaticExporterVisitableVisitor: AssociatedTypeRequirementsVisitor {
    associatedtype Visitor = StaticExporterVisitableVisitor
    associatedtype Input = StaticInterfaceExporter
    associatedtype Output

    func callAsFunction<I: StaticInterfaceExporter>(_ value: I) -> Output
}

private struct StandardStaticExporterVisitableVisitor: StaticExporterVisitableVisitor {
    func callAsFunction<I: StaticInterfaceExporter>(_ value: I) -> (_ visitor: InterfaceExporterVisitor) -> Void {
        value.accept
    }
}

// MARK: AssociatedKit workaround

private struct TestRequest: ExporterRequest {
    var remoteAddress: SocketAddress? {
        nil
    }
}

private struct TestExporter: InterfaceExporter {
    init() {}
    func export<H: Handler>(_ endpoint: Endpoint<H>) {
        fatalError("Not implemented")
    }
    func retrieveParameter<Type: Decodable>(_ parameter: EndpointParameter<Type>, for request: TestRequest) throws -> Type?? {
        fatalError("Not implemented")
    }
}

private struct StaticTestExporter: StaticInterfaceExporter {
    init() {}
    func export<H: Handler>(_ endpoint: Endpoint<H>) {
        fatalError("Not implemented")
    }
}

extension ExporterVisitableVisitor {
    @inline(never)
    @_optimize(none)
    fileprivate func _test() {
        _ = self(TestExporter())
    }
}

extension StaticExporterVisitableVisitor {
    @inline(never)
    @_optimize(none)
    fileprivate  func _test() {
        _ = self(StaticTestExporter())
    }
}
