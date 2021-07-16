//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
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
