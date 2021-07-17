//
// Created by Andreas Bauer on 16.07.21.
//

import ApodiniAuthorization
import ApodiniDatabase

// ToDo maybe also cover the case where the auth requirements are not part of the User object (e.g. ACL list)?
//   => async AuthorizationRequirements?
public protocol InsecureCredentialAuthenticatable: Authenticatable, Model {
    associatedtype Username
    associatedtype Password

    var username: Username { get }
    var password: Password { get }
}
