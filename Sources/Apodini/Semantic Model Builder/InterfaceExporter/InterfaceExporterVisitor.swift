//
// Created by Andreas Bauer on 30.01.21.
//

import NIO

protocol InterfaceExporterVisitor {
    func visit<I: InterfaceExporter>(exporter: I)
}

struct AnyInterfaceExporter {
    private let accept: (_ visitor: InterfaceExporterVisitor) -> Void

    init<I: InterfaceExporter>(_ exporter: I) {
        self.accept = exporter.accept(_:)
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
