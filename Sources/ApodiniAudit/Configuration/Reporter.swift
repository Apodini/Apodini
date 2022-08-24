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

enum Reporter {
    static func generateReportString(_ report: Report, _ webServiceString: String) -> String {
        // Group audits by Endpoint they are related to
        let indexedAudits = Dictionary(grouping: report.audits, by: { $0.endpoint.absolutePath.pathString })
        let sortedEndpoints = Array(indexedAudits.keys).sorted()
        
        var reportStr = ""
        
        addLine(&reportStr)
        addLine(&reportStr, "====================================")
        addLine(&reportStr, "ApodiniAudit Report")
        addLine(&reportStr, "====================================")
        addLine(&reportStr)
        
        var printedSomething = false
        
        for endpoint in sortedEndpoints {
            guard let audits = indexedAudits[endpoint],
                  !audits.flatMap({ $0.findings }).isEmpty else {
                continue
            }
            
            let auditsByHandler = Dictionary(grouping: audits, by: { $0.endpoint.bareHandlerName(webServiceString) })
            let sortedHandlers = Array(auditsByHandler.keys).sorted()
            
            addLine(&reportStr, endpoint)
            
            for handler in sortedHandlers {
                guard let audits = auditsByHandler[handler],
                      !audits.flatMap({ $0.findings }).isEmpty else {
                    continue
                }
                
                addLine(&reportStr, "  \(handler)")
                for audit in audits {
                    guard !audit.findings.isEmpty else {
                        continue
                    }
                    
                    // Sort findings by priority
                    let sortedFindings = audit.findings.sorted(by: \Finding.priority)
                    for finding in sortedFindings {
                        printedSomething = true
                        addLine(&reportStr, "    \(finding.diagnosis)")
                        if let suggestion = finding.suggestion {
                            addLine(&reportStr, "      \(suggestion)")
                        }
                    }
                }
            }
            addLine(&reportStr)
        }
        
        if !printedSomething {
            addLine(&reportStr, "No findings! 🚀")
        }
        
        return reportStr
    }
    
    static func logReport(_ report: Report, _ webServiceString: String) {
        print(generateReportString(report, webServiceString))
    }
    
    private static func addLine(_ reportString: inout String, _ line: String = "") {
        reportString += "\(line)\n"
    }
}

extension Array where Element == EndpointPath {
    var pathString: String {
        if self.count <= 1 {
            return "/"
        }
        return self.map {
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

extension AnyEndpoint {
    func bareHandlerName(_ webServiceString: String) -> String {
        let fullName = self[HandlerReflectiveName.self].rawValue
        
        guard let webServiceIndex = fullName.index(of: webServiceString) else {
            return self[HandlerDescription.self].rawValue
        }
        
        let endOfWebServiceIndex = fullName.index(webServiceIndex, offsetBy: webServiceString.count + 1)
        
        guard let nonLetterIndex = fullName.firstIndex(after: endOfWebServiceIndex, where: {
            [",", " ", ">", "<"].contains($0)
        }) else {
            return self[HandlerDescription.self].rawValue
        }
        
        return String(fullName[endOfWebServiceIndex..<nonLetterIndex])
    }
}

// https://stackoverflow.com/questions/32305891/index-of-a-substring-in-a-string-with-swift
extension StringProtocol {
    func index<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> Index? {
        range(of: string, options: options)?.lowerBound
    }
    func endIndex<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> Index? {
        range(of: string, options: options)?.upperBound
    }
    func indices<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> [Index] {
        ranges(of: string, options: options).map(\.lowerBound)
    }
    func ranges<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> [Range<Index>] {
        var result: [Range<Index>] = []
        var startIndex = self.startIndex
        while startIndex < endIndex,
            let range = self[startIndex...]
                .range(of: string, options: options) {
                result.append(range)
                startIndex = range.lowerBound < range.upperBound ? range.upperBound :
                    index(range.lowerBound, offsetBy: 1, limitedBy: endIndex) ?? endIndex
        }
        return result
    }
}
