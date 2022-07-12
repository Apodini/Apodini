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
    var audits: [Audit] = []
    
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
            audits.append(bestPracticeType.audit(app, endpoint))
        }
    }
    
    func export<H>(blob endpoint: Endpoint<H>) where H: Handler, H.Response.Content == Blob {
        export(endpoint)
    }
    
    func finishedExporting(_ webService: WebServiceModel) {
        // where audit.report.auditResult == .fail {
        for audit in audits {
            app.logger.info("[Audit] \(audit.report.message)")
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
        NoUnderscoresInURLPathSegments.self
    ]
}