library rest_frame.router;

import "package:rest_frame/src/enums/enums.dart";
import "package:rest_frame/src/route.dart";
import "package:rest_frame/src/routing.dart" as routing;
import "dart:io";
import 'dart:mirrors';
import "dart:convert";
import "package:rest_frame/src/annotations/annotation.dart";
import "dart:async";

class Router {

  RestPath _path;
  Router _parent;
  List<Router> _childs = new List<Router>();
  List<Route> _getRoutes = new List<Route>();
  List<Route> _putRoutes = new List<Route>();
  List<Route> _postRoutes = new List<Route>();
  List<Route> _deleteRoutes = new List<Route>();
  List<ErrorHandler> _errorHandler = new List<ErrorHandler>();

  Router(String path, [Router parent]) {
    if (parent != null) {
      _parent = parent;
    }
    _path = new RestPath(path);
  }

  Router.fromAnnotation() {
    List<ClassMirror> restResourceClasses = routing.retrieveRestClassesForIsolate();
    restResourceClasses.forEach((currentRestClass) {
      currentRestClass.metadata.forEach((currentMetaData) {
        if (currentMetaData.type == reflectClass(RestResource)) {
          _createRoutesFromRestClass(currentRestClass, currentMetaData.getField(#path).reflectee);
        }
      });
    });
  }

  /**
   * Creates routes from restClass
   */
  void _createRoutesFromRestClass(ClassMirror restClass, String rootPath) {
    Iterable<DeclarationMirror> restMethods = routing.retrieveRestMethods(restClass);
    restMethods.forEach((method) {
      method.metadata.forEach((methodAnnotation) {
        String path = methodAnnotation.getField(#path).reflectee;
        HttpMethod httpMethod = methodAnnotation.getField(#method).reflectee;
        switch (httpMethod) {
          case HttpMethod.get:
            _getRoutes.add(new Route.fromRestClass(rootPath + path, method));
            break;
          case HttpMethod.put:
            _putRoutes.add(new Route.fromRestClass(rootPath + path, method));
            break;
          case HttpMethod.post:
            _postRoutes.add(new Route.fromRestClass(rootPath + path, method));
            break;
          case HttpMethod.delete:
            _deleteRoutes.add(new Route.fromRestClass(rootPath + path, method));
            break;
          default:
        }
      });
    });
  }

  void get(String path, Function callBack) {
    _getRoutes.add(new Route(_path.path + path, (reflect(callBack) as ClosureMirror)));
  }

  void put(String path, Function callBack) {
    _putRoutes.add(new Route(_path.path + path, (reflect(callBack) as ClosureMirror)));
  }

  void post(String path, Function callBack) {
    _postRoutes.add(new Route(_path.path + path, (reflect(callBack) as ClosureMirror)));
  }

  void delete(String path, Function callBack) {
    _deleteRoutes.add(new Route(_path.path + path, (reflect(callBack) as ClosureMirror)));
  }

  Router child(String path) {
    Router childRouter = new Router(_path.path + path, this);
    this._childs.add(childRouter);
    return childRouter;
  }

  /**
   * Registers an error handler
   */
  void registerErrorHandler(ErrorHandler handler) {
    _errorHandler.add(handler);
  }

  /**
   * Propagates error to error handlers
   */
  void propagateError(HttpRequest request, e) {
    for (ErrorHandler handler in _errorHandler) {
      handler.handleError(request, e);
    }
  }

  /**
   * Get route for request
   */
  Route _registeredRoute(HttpMethod method, Uri requestUri) {
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
      request.response.statusCode = HttpStatus.BAD_REQUEST;
      request.response.close();
    }, test : (e) => e is TypeError).catchError((e) {
      request.response.statusCode = HttpStatus.INTERNAL_SERVER_ERROR;
      propagateError(request, e);
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
    List<Future<dynamic>> paramProcessingFutures = new List<dynamic>();
    for (MethodParameter currentParameter in route.method.parameters) {
      paramProcessingFutures.add(_assignValuesToFunctionParameters(currentParameter, paramsInRequest, request));
    }
    return Future.wait(paramProcessingFutures).then((futureResults) {
      List<dynamic> invokeParameters = new List<dynamic>();
      futureResults.forEach((result) {
        invokeParameters.add(result);
      });
      dynamic callBackReturn = route.method.invoke(invokeParameters);
      _processResponse(request, callBackReturn);
    });

  }

  /**
   * Assigns values from rest request to function parameters
   */
  Future<dynamic> _assignValuesToFunctionParameters(MethodParameter functionParameter, Map<String, String> paramsInRequest, HttpRequest request) {
    Completer completer = new Completer();
    // rest framework annotations
    if (functionParameter.isHttpRequestParameter) {
      completer.complete(request);
    } else if (functionParameter.isRequestBodyParameter) {
      UTF8.decodeStream(request).then((body) {
        if (functionParameter.parameterMirror.type == reflectType(dynamic)) {
          completer.complete(JSON.decode(body));
        } else {
          completer.complete(_parseTypeFromString(functionParameter.parameterMirror, body));
        }
      });
    } else {
      String funcParameterName = functionParameter.pathParamName;
      if (funcParameterName == null || funcParameterName.isEmpty) {
        funcParameterName = MirrorSystem.getName(functionParameter.parameterMirror.simpleName);
      }
      dynamic paramValue = paramsInRequest[funcParameterName];
      if (functionParameter.parameterMirror.type == reflectType(dynamic)) {
        completer.complete(paramValue);
      } else {
        completer.complete(_parseTypeFromString(functionParameter.parameterMirror, paramValue));
      }
    }
    return completer.future;
  }

  /**
   * Parses a string to the type reflected by [mirror]
   */
  dynamic _parseTypeFromString(ParameterMirror mirror, String value) {
      var result = value;
      if (value != null && value.isNotEmpty) {
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

  void _processResponse(HttpRequest request, dynamic invokeResult) {
    String json = JSON.encode(invokeResult);
    request.response.write(json);
    request.response.close();
  }
}

abstract class ErrorHandler {

  void handleError(HttpRequest request, e);
}


