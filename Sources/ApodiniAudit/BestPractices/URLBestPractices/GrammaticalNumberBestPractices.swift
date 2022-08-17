//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Apodini

/// BP14 & BP15
public final class PluralSegmentForStoresAndCollections: BestPractice {
    public static var scope: BestPracticeScopes = .rest
    public static var category: BestPracticeCategories = .linguisticURL
    
    var checkedParameters = [UUID]()
    
    public func check(into audit: Audit, _ app: Application) {
        let path = audit.endpoint[EndpointPathComponentsHTTP.self].value
        
        let idParameterIndices: [Int] = path.enumerated().compactMap { index, pathSegment in
            guard case .parameter(let parameter) = pathSegment else {
                return nil
            }
            
            if checkedParameters.contains(parameter.id) {
                return nil
            }
            
            if parameter.name.lowercased().contains("id") ||
                parameter.identifyingType != nil ||
                parameter.propertyType == UUID.self ||
                parameter.propertyType == Int.self {
                checkedParameters.append(parameter.id)
                return index
            }
            return nil
        }
        
        for index in idParameterIndices {
            // Check what the path segment in front of the ID is
            // If it's not a plural noun, issue a warning
            
            let previousSegment = path[index - 1]
            switch previousSegment {
            case .root:
                audit.recordFinding(BadCollectionSegmentName.firstLevelIdParameter)
            case .parameter:
                audit.recordFinding(BadCollectionSegmentName.parametersInSuccession)
            case .string(let prevSegmentString):
                let lastPart = prevSegmentString.getLastSegment()
                
                if !NLTKInterface.shared.isPluralNoun(lastPart) {
                    audit.recordFinding(BadCollectionSegmentName.nonPluralBeforeParameter(prevSegmentString))
                }
            }
        }
        
        // TODO add inverse: if last segment is singular, then delete would be kinda weird?
    }
    
    public required init() { }
}

enum BadCollectionSegmentName: Finding {
    case parametersInSuccession
    case nonPluralBeforeParameter(_ nonPluralWord: String)
    case firstLevelIdParameter
    
    var diagnosis: String {
        switch self {
        case .parametersInSuccession:
            return "Found two parameters in succession"
        case .nonPluralBeforeParameter(let word):
            return "Found non-plural word \"\(word)\" in front of a parameter"
        case .firstLevelIdParameter:
            return "Found an ID parameter immediately after the path root"
        }
    }
}
