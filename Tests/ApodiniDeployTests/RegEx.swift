////
////  RegEx.swift
////  
////
////  Created by Lukas Kollmer on 2021-04-23.
////
//
//import Foundation
//
//
//struct RegularExpression: Hashable, Equatable {
//    typealias Options = NSRegularExpression.Options
//    typealias MatchingOptions = NSRegularExpression.MatchingOptions
//    
//    
//    private let regex: NSRegularExpression
//    
//    init?(_ pattern: String, options: Options = []) {
//        if let regex = try? NSRegularExpression(pattern: pattern, options: options) {
//            self.regex = regex
//        } else {
//            return nil
//        }
//    }
//    
//    init(_ pattern: String, options: Options = []) throws {
//        self.regex = try NSRegularExpression(pattern: pattern, options: options)
//    }
//}
//
//
//
//extension RegularExpression {
//    func matches(in string: String, options: MatchingOptions = []) -> [Match] {
//        let matches = regex.matches(in: string, options: options, range: string.fullNSRange)
//        return matches.enumerated().map { idx, textCheckingResult -> Match in
//            Match(nsTextCheckingResult: textCheckingResult, regex: self, index: idx, matchedAgainstString: string)
//        }
//    }
//}
//
//
//
//
//extension RegularExpression {
//    struct Match {
//        // The underlying NSTextCheckingResult object
//        let nsTextCheckingResult: NSTextCheckingResult
//        // The regular expression which was used to obtain this match
//        let regex: RegularExpression
//        
//        // The index of this match
//        let index: Int
//        // The string the regex was matched against
//        let matchedAgainstString: String
//        
////
////        subscript(captureGroup idx: Int) -> String {
////
////        }
//    }
//}
//
//
//private extension StringProtocol {
//    var fullNSRange: NSRange {
//        NSRange(startIndex..<endIndex, in: self)
//    }
//}
