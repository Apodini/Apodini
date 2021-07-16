//
// Created by Andreas Bauer on 16.07.21.
//

import Apodini

struct AuthorizationStateContainer<Element: Authenticatable> {
    let element: Element?
    /// A `OptionalAuthorizationMetadata` might find that no authentication information is contained in the request.
    /// That's perfectly fine. Its optional after all. However, it may still need to send out a authentication challenge
    /// if a respective Handler decides to require the authorized credentials.
    /// In that case we need to be able to emit an error with the according authentication challenge (scheme defined).
    /// Therefore, when we encounter a `OptionalAuthorizationMetadata` with no authentication information, we create
    /// an error and save it here and throw it if we need to (see `Authorized` property).
    /// The error might be the result of merging multiple errors emitted by multiple `OptionalAuthorizationMetadata`.
    let potentialError: ApodiniError?

    init () {
        self.init(element: nil)
    }

    private init(element: Element?, potentialError: ApodiniError? = nil) {
        self.element = element
        self.potentialError = potentialError
    }

    func callAsFunction(_ element: Element) -> Self {
        if let existing = self.element {
            fatalError("""
                       AuthorizationStateContainer tried setting Authenticatable instance although one was already present! \
                       Existing: \(existing); New: \(element).
                       """)
        }

        return AuthorizationStateContainer(element: element, potentialError: potentialError)
    }

    func callAsFunction(potentialError: ApodiniError) -> Self {
        AuthorizationStateContainer(element: element, potentialError: self.potentialError?.merge(with: potentialError) ?? potentialError)
    }
}
