//
// Created by Andreas Bauer on 08.07.21.
//

import Apodini

/// An ``AuthenticationVerifier`` is used on the output of an ``AuthenticationScheme`` to instantiate the
/// according ``Authenticatable`` instance and verify its correctness and/or integrity.
///
/// In an ``AuthenticationVerifier`` you can use any common ``Property`` similar as you can in a  ``Handler``.
public protocol AuthenticationVerifier {
    /// The input type received from an ``AuthenticationScheme``.
    associatedtype AuthenticationInfo
    /// The ``Authenticatable`` instantiated from the ``AuthenticationInfo``.
    associatedtype Element: Authenticatable

    /// This method uses the ``AuthenticationInfo`` result received from the respective ``AuthenticationScheme``
    /// to instantiate the ``Element`` instance. The instantiating process might include calls to databases
    /// to complete the ``Authenticatable`` state information.
    /// This method should also verify the correctness of the ``Authenticatable``. This includes password checks
    /// or verification of signatures of e.g. a token.
    ///
    /// - Parameter authenticationInfo: The ``AuthenticationInfo`` received from the ``AuthenticationScheme``.
    /// - Returns: Returns the instantiated and verified ``Element`` instance.
    /// - Throws: Throws an `ApodiniError` if anything gone wrong in the instantiating or verification process.
    ///     For example a respective ``Authenticatable`` might fail the password or signature check.
    func initializeAndVerify(for authenticationInfo: AuthenticationInfo) async throws -> Element
}
