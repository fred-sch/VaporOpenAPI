# VaporOpenAPI

This is currently in early stages of development, not a polished or feature-complete API by a long stretch.

See https://github.com/mattpolzin/VaporOpenAPIExample for an example of a simple app using this library.

You use `VaporTypedRoutes.TypedRequest` instead of `Vapor.Request` to form a request context that can be used to built out an OpenAPI description. You use custom methods to attach your routes to the app. These methods mirror the methods available in Vapor already, but you access them via the `Application.openAPI` routes builder.

```swift

enum WidgetController {
    struct ShowRoute: RouteContext {
        ...
    }
    
    static func show(_ req: TypedRequest<ShowRoute>) -> EventLoopFuture<Response> {
        ...
    }
}

func routes(_ app: Application) {
    app.openAPI.get(
        "widgets",
        ":type".description("The type of widget"),
        ":id",
        use: WidgetController.show 
    ).tags("Widgets")
      .summary("Get a widget")
}
```
