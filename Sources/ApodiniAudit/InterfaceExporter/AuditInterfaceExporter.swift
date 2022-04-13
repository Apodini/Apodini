//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Apodini

final class AuditInterfaceExporter: InterfaceExporter {
    var audits: [Audit] = []
    var app: Application
    
    func export<H: Handler>(_ endpoint: Endpoint<H>) {
        // TODO figure out which ones are silenced for the current endpoint
        for bestPracticeType in Self.bestPractices {
            audits.append(bestPracticeType.audit(app, endpoint))
        }
    }
    
    func export<H>(blob endpoint: Endpoint<H>) where H: Handler, H.Response.Content == Blob {
        export(endpoint)
    }
    
    func finishedExporting(_ webService: WebServiceModel) {
        for audit in audits {
            if audit.report.auditResult == .fail {
                app.logger.info("[Audit] \(audit.report.message)")
            }
        }
    }
    
    init(_ app: Application) {
        self.app = app
    }
}

extension AuditInterfaceExporter {
    static let bestPractices: [BestPractice.Type] = [
        AppropriateLengthForURLPathSegments.self,
        NoUnderscoresInURLPathSegments.self
    ]
}
