//
//  PathComponent.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

public protocol PathComponent {}


extension String: PathComponent {}


struct Identifier<T: Identifiable>: PathComponent {}
