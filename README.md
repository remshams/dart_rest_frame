# Rest Frame
Framework for specifing and mapping rest routes. It is based on the standard HttpRequest object

Features:

* Inline definition of routes/child routes
* Annotations
* Encoding/Decoding from Json to Object and Object to Json
* Exception Handling

## Router
The router is the central class for initialising the routing and defining rest routes.
### Init - Inline
Initialise the router by creating a new instance of the router class.

```dart
Router router  = new Router();
```
Routers also support some kind of base paths

```dart
Router router = new Router("/stock");
```
Routers can be nested (again base paths are optional).

```dart
Router router = new Router("/stock");
Router childrouter = router.child("/bond");
```

### Init - Annotation
It is also possible to initialise the router by annotating the classes as rest resources.

```dart
@RestResource("/bond")
class RestResource {
	...
}
```
Again base path is optional

```dart
@RestResource()
class RestResource {
	...
}
```
The router is intialised by using the fromAnnotation constructor

```dart
Router router = Router.fromAnnotation();
```
**Only the routes in the same isolate will be created/found.**
### Routing
Routes are resolved by passing a HttpRequest to the route method of a registered router

```dart
HttpServer.bind(host, port).then((HttpServer server) {
	server.listen((HttpRequest request) {
   		router.route(request);
  	});
});
```

## Routes
The router provides methods for registering rest routes. Routes can be defined inline or by using annotations.

**It is recommened to either use annotations or defining routes inline. Mixing annotations and inline registering of routes is not fully supported/tested, has known limitations and could lead to issues**
### Inline

```dart
Router router = new Router();
router.get(toCall, "/bond/{id}");
router.post(toCall, "/bond");
router.put(toCall, "/bond/{id}");
router.delete(toCall, "/bond/{id}");
```

### Annotation

```dart
@RestResource("/bond")
class RestResource {
	@RestMethod(HttpMethod.get, "/{id}")
	void getMethod() {

	}
	
	@RestMethod(HttpMethod.post)
	void postMethod() {

	}
	
	@RestMethod(HttpMethod.put, "/{id}")
	void putMethod() {

	}
	
	@RestMethod(HttpMethod.delete, "/{id}")
	void deleteMethod() {

	}
}
```
Routes to childs are also possible

```dart
@RestResource("/stock")
class RestResource {
	@RestMethod(HttpMethod.get, "/{id}")
	void getMethod() {

	}
	
	@RestMethod(HttpMethod.get, "/{stockId}/bond/{bondId}")
	void getMethodChild() {

	}
}
```
In case more than one route are registered for a specific url the http request is mapped to the first match.
## Parameters
The framework supports url parameters and path parameters
### Url Parameters
Url parameters are included in the url by surrounding them with curly brackets

Examples:

	Routes:
	http://localhost:99/stocks/{id}
	http://localhost:99/stocks/{stockId}/bonds/{bondId}
	
	Mappings:
	http://localhost:99/stocks/1
	http://localhost:99/stocks/2/bonds/4
### Path Parameters
Path parameters are specified at the end of the url starting with a "?"

Examples:

	Routes:
	http://localhost:99/stocks{?type}{?filter}
	http://localhost:99/stocks/{stockId}/bonds{?from}{?to}
	
	Mappings:
	http://localhost:99/stocks?type=mytype&filter=new
	http://localhost:99/stocks?type=mytype
	http://localhost:99/stocks/2/bonds?from=1428012000000&to=1428142974369
## Methods
As described the methods for the different routes are specified inline or by using annotations. The framework supports mapping the url- and path parameters to the respective method parameters. If required the HttpRequest can also be passed to the method


The request body as well as the repsonse are decoded/encoded from/to Json.
### Parameters
The frameworks maps the url-/path parameters to a specific method parameter by using the same name or using the path param annotation

```dart
@RestResource("/stock")
class RestResource {
	@RestMethod(HttpMethod.get, "/{?name}")
	void getMethod(String name) {

	}
	
	@RestMethod(HttpMethod.get, "/{stockId}/bond/{bondId}{?name}")
	void testResourceNoPath(int stockId, int bondId, String name) {

	}
}
```
By using the path param annotation the name of the method parameter can be different from the url-/path param

```dart
@RestResource("/stock")
class RestResource {
	@RestMethod(HttpMethod.get, "/{stockId}/{?name}")
	void getMethod(@PathParam() stockId, @PathParam("name") String stockName) {

	}
	
	@RestMethod(HttpMethod.get, "/{stockId}/bond/{bondId}{?name}")
	void testResourceNoPath(@PathParam("stockId") int stock, int bondId, String name) {

	}
}
```
**As of yet path params are only supported when resources and routes are specified using annotations**
### Http Request
In case a method requires the original HttpRequest object it just needs to be added as parameter to the method

```dart
void method(HttpRequest request, String id) {
	
}
```
### Request Body
By annotating a method parameter with the "RequestBody" annotation the framework tries to create the object from the provided json String. Therefore the parameter needs to be typed and a "fromJson" constructor is required

```dart
class MyObject {
	MyObject.fromJson(Map<String, dynamic> json) {
		...
	}
}


void method(HttpRequest request, @RequestBody() MyObject body) {}
```
In case the annotated parameter is dynamic, the json string is passed through.
### Method return value
As for the request body parameter the return value of a method is parsed to a json string in case it is typed and a toJson method is provided

```dart
class MyObject {
	MyObject.fromJson(Map<String, dynamic> json) {
		...
	}
	
	Map<String, dynamic> toJson() {
		Map<String, dynamic> jsonMap = new Map<String, dynamic>();
		...
		return jsonMap;
	}
}

MyObject method(HttpRequest request) {
	MyObject object = new MyObject();
	...
	return object;
}
```
Returning a simple type like string or int is also possible

```dart
String method(HttpRequest request) {
	String returnString;
	...
	return returnString;
}
```
## Exception Handling
The framework handles some basic exceptions. For a custom exception hanlding exception handlers can be registered
### Standard Exceptions
1. 404 - Not found
	* Returned in case the route is not found
2. 500 - Internal Error
	* Returned in case an unexpected error occurs

All standard errors can be overwritten by registering a custom error handler

### Custom Error Handler
The router class provides a method for registering an error handler.

The error handler is required to extend the abstract ErrorHandler class

```dart
abstract class ErrorHandler {
	void handleError(HttpRequest request, e);
}
```
The handler can then be registered for a router instance

```dart
class MyErrorHandler extends ErrorHandler {
	void handleError(request, e) {
		request.response.statusCode = HttpStatus.BAD_REQUEST;
		request.response.close();
	}
}


Router router = new Router.fromAnnotation();
router.registerErrorHanlder(new MyErrorHandler());
```
In case more than one handler is registered the handlers are called in FIFO order.

## Know Limitations
* PathParam annotation is not supported when routes are defined inline.

## ToDo
* Docu
* Further testing
* Optimications
* Support defining routes inline and with annotations (mixed mode)