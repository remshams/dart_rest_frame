library restframework.router;

import "package:restFramework/src/enums.dart";
import "package:restFramework/src/utils/utils.dart";
import "dart:io";
import 'dart:mirrors';
import "dart:convert";

class Router {

  RestPath _path;
  Router _parent;
  List<Router> _childs = new List<Router>();
  List<Route> _getRoutes = new List<Route>();
  List<Route> _putRoutes = new List<Route>();
  List<Route> _postRoutes = new List<Route>();
  List<Route> _deleteRoutes = new List<Route>();

  Router(String path, [Router parent]) {
    if (parent != null) {
      _parent = parent;
    }
    _path = _createPath(path);
  }

  void get(String path, Function callBack) {
    _getRoutes.add(new Route(_createPath(_path.path + path), callBack));
  }

  void put(String path, Function callBack) {
    _putRoutes.add(new Route(_createPath(_path.path + path), callBack));
  }

  void post(String path, Function callBack) {
    _postRoutes.add(new Route(_createPath(_path.path + path), callBack));
  }

  void delete(String path, Function callBack) {
    _deleteRoutes.add(new Route(_createPath(_path.path + path), callBack));
  }

  Router child(String path) {
    Router childRouter = new Router(_path.path + path, this);
    this._childs.add(childRouter);
    return childRouter;
  }

  RestPath _createPath(String path) {
    return new RestPath(path);
  }

  /**
   * Get route for request
   */
  Route registeredRoute(HttpMethod method, Uri requestUri) {
    List<String> routeElements = _path.pathSegments;
    List<String> pathElements = requestUri.pathSegments;
    // Number of elements in request must match router path
    for (int i = 0; i < routeElements.length; i++) {
      if (pathElements[i] == null || routeElements[i] != pathElements[i]) {
        return null;
      }
    }
    Route matchingRoute;
    // Check childs first
    for (int i = 0; i < _childs.length; i++) {
      matchingRoute = _childs[i].registeredRoute(method, requestUri);
      if (matchingRoute != null) {
        return matchingRoute;
      }
    }
    // Check routes of methods
    switch (method) {
      case HttpMethod.get:
        matchingRoute = _retrieveRouteRegisteredForHttpMethod(_getRoutes, requestUri);
        break;
      case HttpMethod.put:
        matchingRoute = _retrieveRouteRegisteredForHttpMethod(_putRoutes, requestUri);
        break;
      case HttpMethod.post:
        matchingRoute = _retrieveRouteRegisteredForHttpMethod(_postRoutes, requestUri);
        break;
      case HttpMethod.delete:
        matchingRoute = _retrieveRouteRegisteredForHttpMethod(_deleteRoutes, requestUri);
        break;
      default:

    }
    return matchingRoute;
  }

  /**
   * Route request
   */
  void route(HttpRequest request) {
    HttpMethod method = HttpMethod.fromString(request.method);
    Route route = registeredRoute(method, request.uri);
    Map<String, String> params = _extractParams(route, request.uri);
    _invokeCallBack(request, route, params);
  }

  /**
   * Retrieve route for request and request method
   */
  Route _retrieveRouteRegisteredForHttpMethod(List<Route> routes, Uri requestUri) {
    for (int i = 0; i < routes.length; i++) {
      if(_isPathMatching(routes[i].path, requestUri)) {
        return routes[i];
      }
    }
    return null;
  }

  /**
   * Checks if paths are matching
   */
  bool _isPathMatching(RestPath basePath, Uri comparePath) {
    List<String> base = basePath.pathSegments;
    List<String> compare = comparePath.pathSegments;
    if (base.length != compare.length) {
      return false;
    }
    for (int i = 0; i < base.length; i ++) {
      if (compare[i].isEmpty) {
        return false;
      // If path elements are not equal check if it is a path parameter
      } else if (compare[i] != base[i]) {
        if (basePath.parameters[i] == null) {
          return false;
        }
      }
    }
    return true;
  }

  /**
   * Extracts the parameters from a request
   * Includes query parameters and path parameters
   */
  Map<String, dynamic> _extractParams(Route route, Uri requestUri) {
    Map<String,String> params = new Map<String, String>();
    params.addAll(requestUri.queryParameters);
    if (route.path.parameters != null) {
      List<String> pathSegments = requestUri.pathSegments;
      route.path.parameters.forEach((key, value) {
        Set<String> uriParameters = value;
        // More specified parameters than length of segment --> does not fit --> skip
        if (uriParameters.length > pathSegments[key].length) {
          return;
        }
        int numberOfSymbols = (pathSegments[key].length / uriParameters.length).floor();
        int counter = 0;
        // Get a value for each parameter
        uriParameters.forEach((paramName) {
          // In case rest is smaller than next chunk assign the rest
          if (counter + numberOfSymbols > pathSegments[key].length) {
            params[paramName] = pathSegments[key].substring(counter, counter + pathSegments[key].length);
          } else {
            params[paramName] = pathSegments[key].substring(counter, counter + numberOfSymbols);
          }
          counter += numberOfSymbols;
        });
      });
    }
    return params;
  }

  /**
   * Invokes the callback method
   */
  void _invokeCallBack(HttpRequest request, Route route, Map<String, String> parameters) {
    ClosureMirror closure = reflect(route.callBack);
    List<dynamic> invokeParameters = new List<dynamic>();
    MethodMirror func = closure.function;
    // TODO: Does not work in case function parameters are not typed
    for (ParameterMirror currentParameter in func.parameters) {
      // Special handling for request object
      if (currentParameter.type.isSubtypeOf(reflectType(HttpRequest))) {
        invokeParameters.add(request);
      } else {
        invokeParameters.add(parameters[MirrorSystem.getName(currentParameter.simpleName)]);
      }
    }
    InstanceMirror closureReturn = closure.apply(invokeParameters);
    _processResponse(request, closureReturn);
  }

  void _processResponse(HttpRequest request, InstanceMirror invokeResult) {
    String json = JSON.encode(invokeResult.reflectee);
    HttpResponse response = request.response;
    response.write(json);
    response.headers.add("Content-Type", "application/json");
    response.statusCode = HttpStatus.OK;
    response.close();
  }
}

class Route {
  RestPath path;
  Function callBack;

  Route(this.path, this.callBack);
}

class RestPath {
  String path;
  List<String> pathSegments;
  Map<int, Set<String>> parameters;
  Set<String> queryParameters;

  RestPath(this.path) {
    parameters = new Map<int, Set<String>>();
    queryParameters = new Set<String>();
    pathSegments = Utils.removeEmptyElementsFromList(path.split("/"));
    _extractParameters(pathSegments);

  }

  // TODO: Optimization possible
  /**
   * Extracts parameters from a route elements
   * Parameters only supported at the end of the path
   */
  void _extractParameters(List<String> pathElements) {
    for (int i = 0; i < pathElements.length; i++) {
      if (pathElements[i].contains("{")) {
        List<String> allElements = pathElements[i].split(new RegExp("\[{.\}]")).where((s) => s.isNotEmpty).toList();
        // In case of query parameters some string needs to be ajusted
        if (pathElements[i].contains("?")) {
          // Replace element with queryParameters by element (e.g.../test{?id}{?name} -> test)
          pathElements[i] = allElements[0];
          for (String currentElement in allElements.sublist(1)) {
            queryParameters.add(currentElement.replaceAll("?", ""));
          }
        } else {
          parameters[i] = new Set.from(allElements);
        }
      }
    }
  }
}
