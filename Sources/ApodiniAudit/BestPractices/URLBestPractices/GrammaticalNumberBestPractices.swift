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
    func checkLastPart(into audit: Audit, _ app: Application, _ lastPart: String)
}

extension GrammaticalNumberBestPractice {
    // Adapted from detectPluralisedNodes in the DOLAR project
    func check(into audit: Audit, _ app: Application) {
        let path = audit.endpoint.absolutePath
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
        
        checkLastPart(into: audit, app, cleanedLastPart)
    }
}

struct PluralLastSegmentForPOST: GrammaticalNumberBestPractice {
    static var scope: BestPracticeScopes = .rest
    static var category: BestPracticeCategories = .linguisticURL
    
    func checkLastPart(into audit: Audit, _ app: Application, _ lastPart: String) {
        if audit.endpoint[Operation.self] != .create {
            return
        }
        
        if !NLTKInterface.shared.isPluralNoun(lastPart) {
            audit.recordFinding("\"\(lastPart)\" is not a plural noun for a POST handler", .fail)
        } else {
            audit.recordFinding("\"\(lastPart)\" is a plural noun for a POST handler", .pass)
        }
    }
}

struct SingularLastSegmentForPUTAndDELETE: GrammaticalNumberBestPractice {
    static var scope: BestPracticeScopes = .rest
    static var category: BestPracticeCategories = .linguisticURL
    
    func checkLastPart(into audit: Audit, _ app: Application, _ lastPart: String) {
        if audit.endpoint[Operation.self] != .update && audit.endpoint[Operation.self] != .delete {
            return
        }
        
        if NLTKInterface.shared.isPluralNoun(lastPart) {
            audit.recordFinding("\"\(lastPart)\" is not a singular noun for a PUT or DELETE handler", .fail)
        } else {
            audit.recordFinding("\"\(lastPart)\" is a singular noun for a PUT or DELETE handler", .pass)
        }
    }
}
