//
//  CodeGeneratorTests.swift
//  DIGenKitTests
//
//  Created by Yosuke Ishikawa on 2017/11/14.
//

import Foundation
import XCTest
import SourceKittenFramework

@testable import DIGenKit

final class CodeGeneratorTests: XCTestCase {
    func testDeclarationPriority() throws {
        // Provide 3 ways to get instance of A
        let code = """
            import DIKit

            struct A: Injectable, FactoryMethodInjectable {
                struct Dependency {
                    let value: Int
                }

                init(dependency: Dependency) {}

                static func makeInstance(dependency: Dependency) {}
            }

            protocol TestResolver: Resolver {
                func provideA() -> A
            }
            """

        let file = File(contents: code)
        let generator = try CodeGenerator(files: [file])
        let contents = try generator.generate().trimmingCharacters(in: .whitespacesAndNewlines)

        // Generated code uses provider method only
        XCTAssertEqual(contents, """
        //
        //  Resolver.swift
        //  Generated by dikitgen.
        //

        import DIKit

        extension TestResolver {

            func resolveA() -> A {
                return provideA()
            }

        }
        """)
    }
    
    func testSharedProviderMethod() throws {
        // Provide 3 ways to get instance of A
        let code = """
            import DIKit

            protocol TestResolver: Resolver {
                func provideA() -> Shared<A>
            }
            """
        
        let file = File(contents: code)
        let generator = try CodeGenerator(files: [file])
        let contents = try generator.generate().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Generated code uses provider method only
        XCTAssertEqual(contents, """
        //
        //  Resolver.swift
        //  Generated by dikitgen.
        //

        import DIKit

        extension TestResolver {

            func resolveA() -> A {
                if let sharedInstance = sharedInstances["A"] {
                    return sharedInstance
                }
                let sharedInstance = provideA()
                sharedInstances["A"] = sharedInstance
                return sharedInstance
            }

        }
        """)
    }
}
