//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini

protocol URLSegmentBestPractice: BestPractice {
    var checkedSegments: [String] { get set }
    
    func checkSegment(segment: String, isParameter: Bool) -> Finding?
}

extension URLSegmentBestPractice {
    public func check(into audit: Audit, _ app: Application) {
        for segment in audit.endpoint.absolutePath {
            if checkedSegments.contains(segment.description) {
                continue
            }
            
            let segmentString: String
            var isParameter = false
            switch(segment) {
            case .string(let path):
                segmentString = path
            case .parameter(let parameter):
                segmentString = parameter.name
                isParameter = true
            default:
                continue
            }
            
            checkedSegments.append(segment.description)
            
            if let finding = checkSegment(segment: segmentString, isParameter: isParameter) {
                audit.recordFinding(finding)
            }
        }
    }
}
