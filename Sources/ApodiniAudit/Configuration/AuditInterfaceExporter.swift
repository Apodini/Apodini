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
    var report: Report
    
    var app: Application
    var parentConfiguration: HTTPExporterConfiguration
    
    var applyRESTBestPractices: Bool {
        parentConfiguration.exportAsREST
    }
    
    func export<H: Handler>(_ endpoint: Endpoint<H>) {
        // Access metadata
        let bestPracticeRule = endpoint[Context.self].get(valueFor: BestPracticeContextKey.self)
        
        guard let bestPractices = app.storage[BestPracticesStorageKey.self] else {
            app.logger.error("Could not find best practices in app storage")
            return
        }
        
        for bestPractice in bestPractices {
            // Check whether this best practice is silenced
            guard bestPracticeRule.action(for: type(of: bestPractice)) != .exclude else {
                continue
            }
            
            guard applyRESTBestPractices || type(of: bestPractice).scope == .all else {
                continue
            }
            report.addAudit(bestPractice.check(for: endpoint, app))
        }
    }
    
    func export<H>(blob endpoint: Endpoint<H>) where H: Handler, H.Response.Content == Blob {
        export(endpoint)
    }
    
    func finishedExporting(_ webService: WebServiceModel) {
        // where audit.report.auditResult == .fail {
        for audit in report.audits {
            for finding in audit.findings {
                app.logger.info("[ApodiniAudit] \(finding.message)")
            }
        }
    }
    
    init(_ app: Application, _ parentConfiguration: HTTPExporterConfiguration) {
        self.app = app
        self.parentConfiguration = parentConfiguration
        self.report = Report()
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
