//
//  String+Trimmed.swift
//  
//
//  Created by Paul Schmiedmayer on 2/24/21.
//

extension String {
    /// Returns the string reduced by `_`. This is needed as `Mirror` shows the names of a types properties with a prefixed `_`.
    /// To use them in the `Updater` correctly, this needs to be removed.
    var trimmedPropertyWrapperName: Self {
        trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "_", with: "")
    }
}
