//
// Created by Andreas Bauer on 02.06.21.
//

/// Represents a error declaration in the source file which should be tested for a compiler error.
/// To define a `ExpectedError` add a comment above the line where the compiler error is expected,
/// adhering to the format like illustrated in the example below:
/// ```swift
/// // error: cannot find operator '++' in scope; did you mean '+= 1'?
/// i++
/// ```
class ExpectedError: CustomStringConvertible {
    var description: String {
        "NegativeCompileTestsRunner.ExpectedError(filePath: \"\(filePath)\", line: \(line), errorMessage: \"\(errorMessage)\", triggered: \(triggered))"
    }

    /// The full path to the file where this Error Definition was captured.
    let filePath: String
    /// The line inside the source file the error declaration refers to.
    /// The error declaration itself is located the line above.
    let line: Int
    /// The expected compiler error message.
    let errorMessage: String

    /// Defines if the the expected compiler error was found in the build output.
    var triggered = false
    /// Lists error messages which match the file and the line number, but have
    /// differing error messages.
    var differingMessages: [String] = []

    init(filePath: String, line: Int, errorMessage: String) {
        self.filePath = filePath
        self.line = line
        self.errorMessage = errorMessage
    }

    /// Marks the error found in the build output with.
    /// - Parameter errorMessage: The error message in the build output for the given file and line.
    func markTriggered(with errorMessage: String) {
        self.triggered = true

        if self.errorMessage.caseInsensitiveCompare(errorMessage) != .orderedSame
               && !differingMessages.contains(errorMessage) {
            differingMessages.append(errorMessage)
        }
    }
}
