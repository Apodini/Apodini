//
//  File.swift
//  
//
//  Created by Nityananda on 07.01.21.
//

struct PathComponentAnalyzer: PathBuilder {
    struct PathParameterAnalyzingResult {
        var parameterMode: HTTPParameterMode?
    }

    var result: PathParameterAnalyzingResult?

    mutating func append<T>(_ parameter: Parameter<T>) {
        result = PathParameterAnalyzingResult(
                parameterMode: parameter.option(for: .http)
        )
    }

    mutating func append(_ string: String) {}

    /// This function does two things:
    ///   * First it checks if the given `_PathComponent` is of type Parameter. If it is it returns
    ///     a `PathParameterAnalyzingResult` otherwise it returns nil.
    ///   * Secondly it retrieves the .http ParameterOption for the Parameter which is stored in the `PathParameterAnalyzingResult`
    static func analyzePathComponentForParameter(_ pathComponent: _PathComponent) -> PathParameterAnalyzingResult? {
        var analyzer = PathComponentAnalyzer()
        pathComponent.append(to: &analyzer)
        return analyzer.result
    }
}
