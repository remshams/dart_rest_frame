library restframework.router;

import "package:restFramework/src/utils/enums.dart";
import "package:restFramework/src/routing/route.dart";
import "dart:io";
import 'dart:mirrors';
import "dart:convert";
import "package:restFramework/src/routing/annotation.dart";

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
  Route _registeredRoute(HttpMethod method, Uri requestUri) {
    List<String> routeElements = _path.pathSegments;
    List<String> pathElements = requestUri.pathSegments;
    // Number of elements in request must match router path
    for (int i = 0; i < routeElements.length; i++) {
      if (routeElements[i].isNotEmpty && pathElements[i] == null || routeElements[i] != pathElements[i]) {
        return null;
      }
    }
    Route matchingRoute;
    // Check childs first
    for (int i = 0; i < _childs.length; i++) {
      matchingRoute = _childs[i]._registeredRoute(method, requestUri);
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
    try {
      HttpMethod method = HttpMethod.fromString(request.method);
      Route route = _registeredRoute(method, request.uri);
      _validateRequest(request, route);
    } catch (e) {
      request.response.statusCode = HttpStatus.INTERNAL_SERVER_ERROR;
      request.response.close();
    }
  }

  /**
   * Checks if request is valid
   * In case it is request is further processed
   */
  void _validateRequest(HttpRequest request, Route route) {
    if (route == null) {
      request.response.statusCode = HttpStatus.NOT_FOUND;
      request.response.close();
      return;
    }
    Map<String, dynamic> params = _extractParams(route, request.uri);
    request.response.statusCode = HttpStatus.OK;
    UTF8.decodeStream(request).then((body) {
      _invokeCallBack(request, route, params, body);
    });

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
        Iterator it = uriParameters.iterator;
        bool isNextParam = it.moveNext();
        while (isNextParam) {
          String currentElement = it.current;
          isNextParam = it.moveNext();
          // In case Param is last in set, assign all remaining values
          if (isNextParam) {
            params[currentElement] = pathSegments[key].substring(counter, counter + numberOfSymbols);
          } else {
            params[currentElement] = pathSegments[key].substring(counter, pathSegments[key].length);
          }
          counter += numberOfSymbols;
        }
      });
    }
    return params;
  }

  /**
   * Invokes the callback method
   */
  void _invokeCallBack(HttpRequest request, Route route, Map<String, String> parameters, String body) {
    ClosureMirror closure = reflect(route.callBack);
    List<dynamic> invokeParameters = new List<dynamic>();
    MethodMirror func = closure.function;
    // TODO: Does not work in case function parameters are not typed
    for (ParameterMirror currentParameter in func.parameters) {
      Set<TypeMirror> typeAnnotations = _retrieveRestFrameworkAnnotations(currentParameter);
      if (typeAnnotations.isNotEmpty) {
        _processAnnotations(currentParameter.type, typeAnnotations, invokeParameters, body);
      } else {
        // Special handling for request object
        if (currentParameter.type.isSubtypeOf(reflectType(HttpRequest))) {
          invokeParameters.add(request);
        } else {
          dynamic paramValue = parameters[MirrorSystem.getName(currentParameter.simpleName)];
          invokeParameters.add(_parseTypeFromString(currentParameter, paramValue));
        }
      }
    }
    InstanceMirror closureReturn = closure.apply(invokeParameters);
    _processResponse(request, closureReturn);
  }

  Set<TypeMirror> _retrieveRestFrameworkAnnotations(ParameterMirror parameterMirror) {
    Set<TypeMirror> annotationTypes = new Set<TypeMirror>();
    for (InstanceMirror currentAnnotaion in parameterMirror.metadata) {
      if (currentAnnotaion.type == reflectType(RequestBody)) {
        annotationTypes.add(currentAnnotaion.type);
      }
    }
    return annotationTypes;
  }

  void _processAnnotations(ClassMirror parameterType, Set<TypeMirror> annotations, List<dynamic> invokeParameters, String requestBody) {
    for (TypeMirror currentAnnotation in annotations) {
      if (currentAnnotation == reflectType(RequestBody)) {
        invokeParameters.add(parameterType.newInstance(#fromJson, [JSON.decode(requestBody)]).reflectee);
      }
    }
  }

  /**
   * Parses a string to the type reflected by [mirror]
   */
  dynamic _parseTypeFromString(ParameterMirror mirror, String value) {
    var result = value;
    if (value != null && !mirror.type.isSubtypeOf(reflectType(String))) {
      // Special handling of bool
      if (mirror.type.isSubtypeOf(reflectType(bool))) {
        result = value.toLowerCase() == "true";
      } else {
        ClassMirror paramTypeMirror = mirror.type;
        result = paramTypeMirror.invoke(#parse, [value]).reflectee;
      }
    }
    return result;
  }

  void _processResponse(HttpRequest request, InstanceMirror invokeResult) {
    String json = JSON.encode(invokeResult.reflectee);
    request.response.write(json);
    request.response.close();
  }
}


