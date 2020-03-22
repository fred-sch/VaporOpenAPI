import XCTest
import OpenAPIReflection
import VaporOpenAPI
import Sampleable
import XCTVapor

final class VaporOpenAPITests: XCTestCase {
    func testExample() throws {
        let app = Application(.testing)
        defer { app.shutdown() }

        app.routes.get("hello", use: TestController.showRoute)
        app.routes.post("hello", use: TestController.createRoute)

        // TODO: Add support for ContentEncoder to JSONAPIOpenAPI
        let jsonEncoder = JSONEncoder()
        if #available(macOS 10.12, *) {
            jsonEncoder.dateEncodingStrategy = .iso8601
            jsonEncoder.outputFormatting = .sortedKeys
        }
        #if os(Linux)
        jsonEncoder.dateEncodingStrategy = .iso8601
        jsonEncoder.outputFormatting = .sortedKeys
        #endif

        let info = OpenAPI.Document.Info(
            title: "Vapor OpenAPI Test API",
            description:
"""
## Descriptive Text
This text supports _markdown_!
""",
            version: "1.0"
        )

        // TODO: get hostname & port from environment
        let servers = [
            OpenAPI.Server(url: URL(string: "http://localhost")!)
        ]

        let components = OpenAPI.Components(
            schemas: [:],
            responses: [:],
            parameters: [:],
            examples: [:],
            requestBodies: [:],
            headers: [:]
        )

        let paths = try app.routes.openAPIPathItems(using: jsonEncoder)

        let document = OpenAPI.Document(
            info: info,
            servers: servers,
            paths: paths,
            components: components,
            security: []
        )

        print(String(data: try jsonEncoder.encode(document), encoding: .utf8)!)

        XCTAssertEqual(document.paths.count, 1)
        XCTAssertNotNil(document.paths["/hello"]?.get)
        XCTAssertNotNil(document.paths["/hello"]?.post)
        XCTAssertNotNil(document.paths["/hello"]?.post?.requestBody?.b?.content[.json]?.example)
    }
}

struct CreatableResource: Codable, Sampleable, OpenAPIExampleProvider {
    let stringValue: String

    static let sample: Self = .init(stringValue: "hello world!")
}

struct TestShowRouteContext: RouteContext {
    typealias RequestBodyType = EmptyRequestBody

    static let shared = Self()

    let badQuery: StringQueryParam = .init(name: "failHard")
    let echo: IntegerQueryParam = .init(name: "echo")

    let success: ResponseContext<String> = .init { response in
        response.headers = Self.plainTextHeader
        response.status = .ok
    }

    let badRequest: CannedResponse<String> = .init(
        response: Response(
            status: .badRequest,
            headers: Self.plainTextHeader,
            body: .empty
        )
    )

    static let plainTextHeader = HTTPHeaders([
        (HTTPHeaders.Name.contentType.description, HTTPMediaType.plainText.serialize())
    ])
}

struct TestCreateRouteContext: RouteContext {
    typealias RequestBodyType = CreatableResource

    static let shared = Self()

    let badQuery: StringQueryParam = .init(name: "failHard")

    let success: ResponseContext<String> = .init { response in
        response.headers = Self.plainTextHeader
        response.status = .ok
    }

    let badRequest: CannedResponse<String> = .init(
        response: Response(
            status: .badRequest,
            headers: Self.plainTextHeader,
            body: .empty
        )
    )

    static let plainTextHeader = HTTPHeaders([
        (HTTPHeaders.Name.contentType.description, HTTPMediaType.plainText.serialize())
    ])
}

final class TestController {
    static func showRoute(_ req: TypedRequest<TestShowRouteContext>) -> EventLoopFuture<Response> {
        if req.query.badQuery != nil {
            return req.response.badRequest
        }
        if let text = req.query.echo {
            return req.response.success.encode("\(text)")
        }
        return req.response.success.encode("Hello")
    }

    static func createRoute(_ req: TypedRequest<TestCreateRouteContext>) -> EventLoopFuture<Response> {
        if req.query.badQuery != nil {
            return req.response.badRequest
        }
        return req.response.success.encode("Hello")
    }
}
