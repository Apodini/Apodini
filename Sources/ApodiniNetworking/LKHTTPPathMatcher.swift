import ApodiniUtils


struct LKHTTPPathMatcher {
    struct MatchResult: Hashable {
        /// The penalty associated with this match. Lower scores are better.
        fileprivate(set) var penaltyScore: Int = 0
        fileprivate(set) var parameters = LKHTTPRequest.ParametersStorage()
    }
    
    
    // Config
    /// Whether or not to disable case sensitivity requirements when matching verbatim (i.e. non-parameter and non-wildcard) path components
    private let allowsCaseInsensitiveMatching: Bool
    /// Whether or not the matcher should allow multi-component wildcards (e.g.: `**`) to also match zero path components
    private let allowsEmptyMultiWildcards: Bool
    
    // Input
    private let urlComponents: [String]
    private let pathComponents: [LKHTTPPathComponent]
    
    // State
    private var urlComponentsIdx: Int = 0
    private var pathComponentsIdx: Int = 0
    
    // Output
    private var wipResult = MatchResult()
    private var potentialMatches: Set<MatchResult> = []
    
    
    static func match(
        url: LKURL,
        against inputPathComponents: [LKHTTPPathComponent],
        allowsCaseInsensitiveMatching: Bool,
        allowsEmptyMultiWildcards: Bool
    ) -> LKHTTPRequest.ParametersStorage? {
        var path = url.path
        if path.hasPrefix("/") && path.count > 1 {
            path.removeFirst()
        }
//        if !path.hasSuffix("/") {
//            path.append("/")
//        }
        if path.isEmpty || path == "/" { // TODO the 2nd case probably never happens bc we'd remove the slash above???!!!!!!!
            // We're accessing the root path, which means that there are no parameters, be it named or wildcard.
            if inputPathComponents.isEmpty {
                return .init()
            } else {
                return nil
            }
        }
        var matcher = Self(
            allowsCaseInsensitiveMatching: allowsCaseInsensitiveMatching,
            allowsEmptyMultiWildcards: allowsEmptyMultiWildcards,
            urlComponents: path.components(separatedBy: "/"),
            pathComponents: inputPathComponents
        )
        return matcher.match()?.parameters
    }
    
    
    private enum MatchOneResult {
        case abort
        case successAndContinue
        case successAndReturn
    }
    
    private mutating func match() -> MatchResult? {
        loop: while true {
            switch matchOne() {
            case .abort:
                return nil
            case .successAndContinue:
                continue
            case .successAndReturn:
                break loop
            }
        }
        
        switch potentialMatches.count {
        case 0:
            // No results :/
            return nil
        case 1:
            return potentialMatches.first!
        default:
            let matchesSorted = potentialMatches.sorted(by: \.penaltyScore, ascending: true)
            if matchesSorted[0].penaltyScore < matchesSorted[1].penaltyScore {
                return matchesSorted[0]
            } else {
                fatalError("Multiple match results with same penalty.")
            }
            //return potentialMatches.min { $0.score < $1.score }
        }
    }
    
    
    private mutating func matchOne() -> MatchOneResult {
        let currentUrlComponent: String
        let currentPathComponent: LKHTTPPathComponent
        
        switch (urlComponents[safe: urlComponentsIdx], pathComponents[safe: pathComponentsIdx]) {
        case (.none, .none):
            // we've run out of both url and path components.
            // Since we only end up here if everything coming before matched, we can consider the url to be successfully matched
            potentialMatches.insert(wipResult)
            wipResult = .init()
            return .successAndReturn
        case (.none, .some(_)):
            // We've run out of url components, but there's still path components waiting to be matched
            // TODO differentiate how we respond, based on the specific remaining path component? probably not necessary since the only one that would be allowed to match here would be the wildcard, which is already handled below...
            return .abort
        case (.some(_), .none):
            // We still have url components to match, but no path components to match them against
            return .abort
        case (.some(let urlComponent), .some(let pathComponent)):
            currentUrlComponent = urlComponent
            currentPathComponent = pathComponent
        }
        
        switch currentPathComponent {
        case .verbatim(let value):
            if currentUrlComponent.compare(value, options: allowsCaseInsensitiveMatching ? [.caseInsensitive] : []) != .orderedSame {
                print("'\(currentUrlComponent)' did not match against '\(value)', with allowCI=\(allowsCaseInsensitiveMatching)")
                return .abort
            }
            urlComponentsIdx += 1
            pathComponentsIdx += 1
            return .successAndContinue
        
        case .namedParameter(let name):
            wipResult.parameters.namedParameters[name] = currentUrlComponent
            urlComponentsIdx += 1
            pathComponentsIdx += 1
            return .successAndContinue
        
        case .wildcardSingle:
            wipResult.parameters.singleComponentWildcards[pathComponentsIdx] = currentUrlComponent
            wipResult.penaltyScore += 1 // i penalty per matched wildcard
            urlComponentsIdx += 1
            pathComponentsIdx += 1
            return .successAndContinue
        
        case .wildcardMultiple:
            // We've reached a point where either:
            // - a multi-component (1+) wildcard pattern is about to start, with the current component as its first component,
            // - an empty multi-component wildcard pattern is (not) about to start, but we don't know that
            // - we're already in a multi-component wildcard pattern, and need to continue
            // The problem about all this is that we don't know how many url components the wildcard should consume.
            // So what we do is that we create multiple copies of the current parser, and have them attempt to parse the url components,
            // with different assumptions as to how long the wildcard should be
            for wildcardLength in (allowsEmptyMultiWildcards ? 0 : 1)..<(urlComponents.endIndex - urlComponentsIdx) {
                var copy = self
                copy.wipResult.parameters.multipleComponentWildcards[copy.pathComponentsIdx] = Array(copy.urlComponents[copy.urlComponentsIdx...(copy.urlComponentsIdx + wildcardLength)])
                copy.urlComponentsIdx += wildcardLength
                copy.pathComponentsIdx += 1
                copy.wipResult.penaltyScore += wildcardLength * 1 // one penalty per matched wildcard component // TODO adjust this value?
                if let result = copy.match() {
                    potentialMatches.insert(result)
                    potentialMatches.formUnion(copy.potentialMatches)
                }
            }
            return .successAndReturn
        }
    }
}

