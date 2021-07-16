//
// This source file is part of the Apodini open source project
// 
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//
@testable import Apodini
@_implementationOnly import Runtime
import XCTest
import XCTApodini

class EmptyComponentTests: ApodiniTests {
    private struct NeverComponent: Component {
        typealias Content = Never
    }
    
    private struct NeverHandler: Handler {
        typealias Response = Never
    }
    
    func testEmptyComponent() throws {
        XCTAssertRuntimeFailure(EmptyComponent().content)
        
        let componentSharedSemanticModelBuilder = SemanticModelBuilder(app)
        let componentSyntaxTreeVisitor = SyntaxTreeVisitor(modelBuilder: componentSharedSemanticModelBuilder)
        EmptyComponent().accept(componentSyntaxTreeVisitor)
        componentSyntaxTreeVisitor.finishParsing()
        XCTAssertEqual(componentSharedSemanticModelBuilder.collectedEndpoints.count, 0)
        
        
        let handlerSharedSemanticModelBuilder = SemanticModelBuilder(app)
        let handlerSyntaxTreeVisitor = SyntaxTreeVisitor(modelBuilder: handlerSharedSemanticModelBuilder)
        EmptyHandler().accept(handlerSyntaxTreeVisitor)
        handlerSyntaxTreeVisitor.finishParsing()
        XCTAssertEqual(componentSharedSemanticModelBuilder.collectedEndpoints.count, 0)
    }
    
    func testNeverRuntimeErrors() throws {
        XCTAssertRuntimeFailure(NeverComponent().content)
        XCTAssertRuntimeFailure(NeverHandler().handle())
    }
}
