//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Apodini

protocol GrammaticalNumberBestPractice: BestPractice {
    func checkLastPart(into report: AuditReport, _ app: Application, _ lastPart: String)
}

extension GrammaticalNumberBestPractice {
    // Adapted from detectPluralisedNodes in the DOLAR project
    func check(into report: AuditReport, _ app: Application) {
        let path = report.endpoint.absolutePath
        let lastSegment = path.last
        let lastSegmentString: String
        
        switch(lastSegment) {
        case .root:
            return
        case .string(let path):
            lastSegmentString = path
        case .parameter(let parameter):
            if parameter.scopedEndpointHasDefinedParameter {
                lastSegmentString = parameter.name
            } else {
                return
            }
        case .none:
            return
        }
        
        // Split last segment into words
        let lastSegmentParts = lastSegmentString.splitIntoWords(delimiters: [
            .uppercase,
            .notAlphaNumerical
        ])
        
        guard let lastPart = lastSegmentParts.last else {
            return
        }
        
        // Build cleanup regex
        guard let cleanUpRegex = try? NSRegularExpression(pattern: "[^a-zA-Z0-9]") else {
            fatalError("Could not build regexes")
        }
        
        let cleanedLastPart = cleanUpRegex.stringByReplacingMatches(in: lastPart, options: [], range: NSMakeRange(0, lastPart.count), withTemplate: "")
        
        checkLastPart(into: report, app, cleanedLastPart)
    }
}

struct PluralLastSegmentForPOST: GrammaticalNumberBestPractice {
    var scope: BestPracticeScopes = .rest
    var category: BestPracticeCategories = .linguisticURL
    
    func checkLastPart(into report: AuditReport, _ app: Application, _ lastPart: String) {
        if report.endpoint[Operation.self] != .create {
            return
        }
        
        if !NLTKInterface.shared.isPluralNoun(lastPart) {
            report.recordFinding("\"\(lastPart)\" is not a plural noun for a POST handler", .fail)
        } else {
            report.recordFinding("\"\(lastPart)\" is a plural noun for a POST handler", .success)
        }
    }
}

struct SingularLastSegmentForPUTAndDELETE: GrammaticalNumberBestPractice {
    var scope: BestPracticeScopes = .rest
    var category: BestPracticeCategories = .linguisticURL
    
    func checkLastPart(into report: AuditReport, _ app: Application, _ lastPart: String) {
        if report.endpoint[Operation.self] != .update && report.endpoint[Operation.self] != .delete {
            return
        }
        
        if NLTKInterface.shared.isPluralNoun(lastPart) {
            report.recordFinding("\"\(lastPart)\" is not a singular noun for a PUT or DELETE handler", .fail)
        } else {
            report.recordFinding("\"\(lastPart)\" is a singular noun for a PUT or DELETE handler", .success)
        }
    }
}
