library restframework.router;

import "package:restFramework/src/utils/enums.dart";
import "package:restFramework/src/routing/route.dart";
import "package:restFramework/src/routing/routing.dart" as routing;
import "dart:io";
import 'dart:mirrors';
import "dart:convert";
import "package:restFramework/src/routing/annotation.dart";
import "dart:async";

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

  Router.fromRestClasses() {
    // TODO Implementation
    MirrorSystem mirrorSystem = currentMirrorSystem();
    mirrorSystem.libraries.forEach((lk, l) {
      l.declarations.forEach((dk, d) {
        if(d is ClassMirror) {
          ClassMirror cm = d as ClassMirror;
          cm.metadata.forEach((md) {
            InstanceMirror metadata = md as InstanceMirror;
            if(metadata.type == reflectClass(RestRessource)) {
              print('found: ${cm.simpleName} ${metadata.getField(#path).reflectee}');
            }
          });
        }
      });
    });
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
        matchingRoute = routing.retrieveRouteRegisteredForHttpMethod(_getRoutes, requestUri);
        break;
      case HttpMethod.put:
        matchingRoute = routing.retrieveRouteRegisteredForHttpMethod(_putRoutes, requestUri);
        break;
      case HttpMethod.post:
        matchingRoute = routing.retrieveRouteRegisteredForHttpMethod(_postRoutes, requestUri);
        break;
      case HttpMethod.delete:
        matchingRoute = routing.retrieveRouteRegisteredForHttpMethod(_deleteRoutes, requestUri);
        break;
      default:

    }
    return matchingRoute;
  }

  /**
   * Route request
   */
  void route(HttpRequest request) {
    new Future.sync(() {
      HttpMethod method = HttpMethod.fromString(request.method);
      Route route = _registeredRoute(method, request.uri);
      return _validateRequest(request, route);
    }).catchError((e) {
      request.response.statusCode = HttpStatus.INTERNAL_SERVER_ERROR;
      request.response.close();
    });
  }

  /**
   * Checks if request is valid
   * In case it is request is further processed
   */
  Future _validateRequest(HttpRequest request, Route route) {
    if (route == null) {
      request.response.statusCode = HttpStatus.NOT_FOUND;
      request.response.close();
      return null;
    }
    Map<String, dynamic> paramsInRequest = _extractParams(route, request.uri);
    request.response.statusCode = HttpStatus.OK;
    return _invokeCallBack(request, route, paramsInRequest);

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
  Future _invokeCallBack(HttpRequest request, Route route, Map<String, String> paramsInRequest) {
    ClosureMirror closure = reflect(route.callBack);
    List<Future<dynamic>> paramProcessingFutures = new List<dynamic>();
    MethodMirror func = closure.function;
    for (ParameterMirror currentParameter in func.parameters) {
      paramProcessingFutures.add(_assignValuesToFunctionParameters(currentParameter, paramsInRequest, request));
    }
    return Future.wait(paramProcessingFutures).then((futureResults) {
      List<dynamic> invokeParameters = new List<dynamic>();
      futureResults.forEach((result) {
        invokeParameters.add(result);
      });
      InstanceMirror closureReturn = closure.apply(invokeParameters);
      _processResponse(request, closureReturn);
    });

  }

  /**
   * Extract RestFramework Annotation of function parameter
   */
  Set<TypeMirror> _retrieveRestFrameworkFunctionAnnotations(ParameterMirror parameterMirror) {
    Set<TypeMirror> annotationTypes = new Set<TypeMirror>();
    for (InstanceMirror currentAnnotaion in parameterMirror.metadata) {
      if (currentAnnotaion.type == reflectType(RequestBody)) {
        annotationTypes.add(currentAnnotaion.type);
      }
    }
    return annotationTypes;
  }

  /**
   * Assigns values from rest request to function parameters
   */
  Future<dynamic> _assignValuesToFunctionParameters(ParameterMirror functionParameter, Map<String, String> paramsInRequest, HttpRequest request) {
    Completer completer = new Completer();
    // rest framework annotations
    Set<TypeMirror> typeAnnotations = _retrieveRestFrameworkFunctionAnnotations(functionParameter);
    // In case function parameter has annotations, process them
    if (typeAnnotations.isNotEmpty) {
      _processAnnotations(functionParameter, typeAnnotations, request, completer);
    } else {
      // Special handling for request object
      if (functionParameter.type == reflectType(HttpRequest)) {
        completer.complete(request);
      // In case of untyped parameter pass string
      } else if (functionParameter.type == reflectType(dynamic)) {
        dynamic paramValue = paramsInRequest[MirrorSystem.getName(functionParameter.simpleName)];
        completer.complete(paramValue);
      } else {
        dynamic paramValue = paramsInRequest[MirrorSystem.getName(functionParameter.simpleName)];
        completer.complete(_parseTypeFromString(functionParameter, paramValue));
      }
    }
    return completer.future;
  }

  void _processAnnotations(ParameterMirror functionParameter, Set<TypeMirror> annotations, HttpRequest request, Completer completer) {
    for (TypeMirror currentAnnotation in annotations) {
      if (currentAnnotation == reflectType(RequestBody)) {
        UTF8.decodeStream(request).then((body) {
          completer.complete(_parseTypeFromString(functionParameter, body));
        });
      }
    }
  }

  /**
   * Parses a string to the type reflected by [mirror]
   */
  dynamic _parseTypeFromString(ParameterMirror mirror, String value) {
      var result = value;
      if (value != null) {
        ClassMirror classMirrorOfType = mirror.type;
        if (mirror.type.isSubtypeOf(reflectType(String))) {
          result = value;
        } else if (classMirrorOfType.declarations.containsKey(#parse)) {
          result = classMirrorOfType.invoke(#parse, [value]).reflectee;
        } else if (mirror.type.isSubtypeOf(reflectType(bool))) {
          result = value.toLowerCase() == "true";
        // TODO Throws exception in case provided value is not a valid json string
        } else {
          result = classMirrorOfType.newInstance(#fromJson, [JSON.decode(value)]).reflectee;
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


