//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Apodini
import ApodiniHTTP

final class AuditInterfaceExporter: InterfaceExporter {
    var reports: [AuditReport] = []
    
    var app: Application
    var parentConfiguration: HTTPExporterConfiguration
    
    var applyRESTBestPractices: Bool {
        parentConfiguration.exportAsREST
    }
    
    func export<H: Handler>(_ endpoint: Endpoint<H>) {
        // FUTURE figure out which ones are silenced for the current endpoint
        for bestPracticeType in Self.bestPractices {
            guard applyRESTBestPractices || bestPracticeType.scope == .all else {
                continue
            }
            reports.append(bestPracticeType.check(for: endpoint, app))
        }
    }
    
    func export<H>(blob endpoint: Endpoint<H>) where H: Handler, H.Response.Content == Blob {
        export(endpoint)
    }
    
    func finishedExporting(_ webService: WebServiceModel) {
        // where audit.report.auditResult == .fail {
        for report in reports {
            for finding in report.findings {
                app.logger.info("[Audit] \(finding.message)")
            }
        }
    }
    
    init(_ app: Application, _ parentConfiguration: HTTPExporterConfiguration) {
        self.app = app
        self.parentConfiguration = parentConfiguration
    }
}

extension AuditInterfaceExporter {
    static let bestPractices: [BestPractice.Type] = [
        AppropriateLengthForURLPathSegments.self,
        NoUnderscoresInURLPathSegments.self,
        NoCRUDVerbsInURLPathSegments.self,
        LowercaseURLPathSegments.self,
        NoFileExtensionsInURLPathSegments.self,
        ContextualisedResourceNames.self,
        GetHasComplexReturnType.self
    ]
}
