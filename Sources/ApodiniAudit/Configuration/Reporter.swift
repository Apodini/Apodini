//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Apodini
import ApodiniNetworking

class Reporter {
    static func logReport(_ report: Report) {
        // Group audits by Endpoint they are related to
        let indexedAudits = Dictionary(grouping: report.audits, by: { $0.endpoint.absolutePath.pathString })
        let sortedEndpoints = Array(indexedAudits.keys).sorted()
        
        print()
        print("====================================")
        print("ApodiniAudit Report")
        print("====================================")
        print()
        
        var printedSomething = false
        
        for endpoint in sortedEndpoints {
            guard let audits = indexedAudits[endpoint],
                  !audits.flatMap({ $0.findings }).isEmpty else {
                continue
            }
            
            print(endpoint)
            
            for audit in audits {
                guard !audit.findings.isEmpty else {
                    continue
                }
                
                // Sort findings by priority
                let sortedFindings = audit.findings.sorted(by: \Finding.priority)
                for finding in sortedFindings {
                    printedSomething = true
                    print("  \(finding.diagnosis)")
                }
            }
            print()
        }
        
        if !printedSomething {
            print("No findings! 🚀")
        }
        
//        // Sort audits by best practice priority
//        let sortedAudits = report.audits.sorted { (audit1, audit2) in
//            if type(of: audit1.bestPractice).priority < type(of: audit2.bestPractice).priority {
//                return true
//            }
//            return false
//        }
    }
    
    static private func printEndpoint(_ endpoint: AnyEndpoint) {
        // Get method
        let method = HTTPMethod(endpoint[Operation.self])
        let endpointString = endpoint.absolutePath.pathString
        
        print("\(method) \(endpointString)")
    }
}

extension Array where Element == EndpointPath {
    var pathString: String {
        self.map {
            $0.segmentString
        }
        .joined(separator: "/")
    }
}

extension EndpointPath {
    var segmentString: String {
        switch self {
        case .root:
            return ""
        case .string(let str):
            return str
        case .parameter(let par):
            return "{\(par.name)}"
        }
    }
}
