//
//  File.swift
//  
//
//  Created by Paul Schmiedmayer on 6/25/20.
//

protocol PathComponent {}

extension String: PathComponent {}

struct Identifier<T: Identifiable>: PathComponent {}
