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
/// Ensures that ID parameters are preceded by a plural noun, e.g. like this:
/// `/posts/{postId}`
///
/// This increases readability by differentiating these collections of resources from singleton resources, such as
/// `/user/profilepicture`
public final class PluralSegmentForStoresAndCollections: BestPractice {
    public static var scope: BestPracticeScopes = .rest
    public static var category: BestPracticeCategories = .linguisticURL
    
    var checkedParameters = [UUID]()
    var configuration = PluralSegmentConfiguration()
    
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
            // Check the grammatical number of the path segment in front of the ID.
            // If it's not a plural noun, issue a warning.
            
            let previousSegment = path[index - 1]
            switch previousSegment {
            case .root:
                audit.recordFinding(BadCollectionSegmentName.firstLevelIdParameter)
            case .parameter:
                audit.recordFinding(BadCollectionSegmentName.parametersInSuccession)
            case .string(let prevSegmentString):
                let lastPart = prevSegmentString.getLastSegment()
                
                if !configuration.allowedSegments.contains(prevSegmentString) &&
                    !NLTKInterface.shared.isPluralNoun(lastPart) {
                    audit.recordFinding(BadCollectionSegmentName.nonPluralBeforeParameter(prevSegmentString))
                }
            }
        }
    }
    
    public required init() { }
    
    init(configuration: PluralSegmentConfiguration) {
        self.configuration = configuration
    }
}

public struct PluralSegmentConfiguration: BestPracticeConfiguration {
    var allowedSegments: [String]
    
    public func configure() -> BestPractice {
        PluralSegmentForStoresAndCollections(configuration: self)
    }
    
    public init(allowedSegments: [String] = []) {
        self.allowedSegments = allowedSegments
    }
}

enum BadCollectionSegmentName: Finding, Equatable {
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
