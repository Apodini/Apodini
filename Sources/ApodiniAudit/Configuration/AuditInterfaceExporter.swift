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
    
    var webServiceString: String
    
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
        Reporter.logReport(report, webServiceString)
    }
    
    init(_ app: Application, _ parentConfiguration: HTTPExporterConfiguration, _ bestPractices: [BestPractice], _ webServiceString: String) {
        self.app = app
        self.parentConfiguration = parentConfiguration
        self.report = Report()
        self.bestPractices = bestPractices
        self.webServiceString = webServiceString
    }
}

extension AuditInterfaceExporter {
    static let defaultBestPracticeConfigurations: [BestPracticeConfiguration] = [
        // Suggestions
        EmptyBestPracticeConfiguration<EncourageETags>(),
        
        // Type Best Practices
        EmptyBestPracticeConfiguration<EndpointHasComplexReturnType>(),
        
        // Syntactic URL Segment Best Practices
        AppropriateLengthForURLPathSegmentsConfiguration(),
        EmptyBestPracticeConfiguration<LowercaseURLPathSegments>(),
        EmptyBestPracticeConfiguration<NoCRUDVerbsInURLPathSegments>(),
        EmptyBestPracticeConfiguration<NoFileExtensionsInURLPathSegments>(),
        EmptyBestPracticeConfiguration<NoNumbersOrSymbolsInURLPathSegments>(),
        EmptyBestPracticeConfiguration<NoUnderscoresInURLPathSegments>(),
        
        // Linguistic URL Best Practices
//        EmptyBestPracticeConfiguration<ContextualisedResourceNames>(),
        EmptyBestPracticeConfiguration<PluralSegmentForStoresAndCollections>(),
//        EmptyBestPracticeConfiguration<SingularLastSegmentForPUTAndDELETE>(),
        
        // Parameter BPs
        ReasonableParameterCountConfiguration()
    ]
}
