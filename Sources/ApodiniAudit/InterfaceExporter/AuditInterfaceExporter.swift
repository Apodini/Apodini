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
        guard let bestPractices = app.storage[BestPracticesStorageKey.self] else {
            app.logger.error("Could not find best practices in app storage")
            return
        }
        // FUTURE figure out which ones are silenced for the current endpoint
        for bestPractice in bestPractices {
            guard applyRESTBestPractices || bestPractice.scope == .all else {
                continue
            }
            reports.append(bestPractice.check(for: endpoint, app))
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
    static let defaultBestPracticeConfigurations: [BestPracticeConfiguration] = [
        AppropriateLengthForURLPathSegmentsConfiguration(),
        EmptyBestPracticeConfiguration<NoUnderscoresInURLPathSegments>(),
        EmptyBestPracticeConfiguration<NoCRUDVerbsInURLPathSegments>(),
        EmptyBestPracticeConfiguration<LowercaseURLPathSegments>(),
        EmptyBestPracticeConfiguration<NoFileExtensionsInURLPathSegments>(),
        EmptyBestPracticeConfiguration<ContextualisedResourceNames>(),
        EmptyBestPracticeConfiguration<GetHasComplexReturnType>(),
        EmptyBestPracticeConfiguration<PluralLastSegmentForPOST>(),
        EmptyBestPracticeConfiguration<SingularLastSegmentForPUTAndDELETE>()
    ]
}
