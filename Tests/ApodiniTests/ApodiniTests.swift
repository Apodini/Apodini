//
// This source file is part of the Apodini open source project
// 
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//
import XCTApodini
@testable import Apodini
@testable import ApodiniDatabase


class ApodiniTests: XCTApodiniTest {
    // Model Objects
    var bird1 = Bird(name: "Swift", age: 5)
    var bird2 = Bird(name: "Corvus", age: 1)
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        try super.addMigrations(CreateBird())
        
        try bird1.create(on: database()).wait()
        try bird2.create(on: database()).wait()
    }
}
