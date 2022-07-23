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
    var bestPractices: [BestPractice]
    
    var applyRESTBestPractices: Bool {
        parentConfiguration.exportAsREST
    }
    
    func export<H: Handler>(_ endpoint: Endpoint<H>) {
        // Access metadata
        let bestPracticeInclusionRule = endpoint[Context.self].get(valueFor: BestPracticeInclusionRuleContextKey.self)
        
        for bestPractice in self.bestPractices {
            // Check whether this best practice is silenced
            guard bestPracticeInclusionRule.action(for: type(of: bestPractice)) != .exclude else {
                continue
            }
            
            // Check whether the scope of this best practice matches the parentConfiguration
            // I.e. we only want to run HTTP best practices for HTTP APIs etc.
            let scope = applyRESTBestPractices ? BestPracticeScopes.rest : .http
            guard type(of: bestPractice).scope.contains(scope) else {
                continue
            }
            
            report.addAudit(bestPractice.check(for: endpoint, app))
        }
    }
    
    func export<H>(blob endpoint: Endpoint<H>) where H: Handler, H.Response.Content == Blob {
        export(endpoint)
    }
    
    func finishedExporting(_ webService: WebServiceModel) {
        // Call finishCheck for every Audit
        for audit in report.audits {
            audit.bestPractice.finishCheck(for: audit, app)
        }
        
        // Export the report
        for audit in report.audits {
            for finding in audit.findings {
                app.logger.info("[ApodiniAudit] \(finding.diagnosis)")
            }
        }
    }
    
    init(_ app: Application, _ parentConfiguration: HTTPExporterConfiguration, _ bestPractices: [BestPractice]) {
        self.app = app
        self.parentConfiguration = parentConfiguration
        self.report = Report()
        self.bestPractices = bestPractices
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
        EmptyBestPracticeConfiguration<GETHasComplexReturnType>(),
        EmptyBestPracticeConfiguration<PluralSegmentForStores>(),
        EmptyBestPracticeConfiguration<SingularLastSegmentForPUTAndDELETE>(),
        EmptyBestPracticeConfiguration<NoNumbersOrSymbolsInURLPathSegments>()
    ]
}
