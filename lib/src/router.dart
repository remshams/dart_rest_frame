library restframework.router;

import "package:restFramework/src/enums.dart";
import "package:restFramework/src/utils/utils.dart";
import "dart:io";

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

  Route registeredRoute(HttpMethod method, Uri requestUri) {
    List<String> routeElements = _path.pathSegments;
    List<String> pathElements = requestUri.pathSegments;
    for (int i = 0; i < routeElements.length; i++) {
      if (pathElements[i] == null || routeElements[i] != pathElements[i]) {
        return null;
      }
    }
    List<String> pathElementsWithoutRootPath = pathElements.sublist(routeElements.length);
    Route matchingRoute;
    for (int i = 0; i < _childs.length; i++) {
      matchingRoute = _childs[i].registeredRoute(method, requestUri);
      if (matchingRoute != null) {
        return matchingRoute;
      }
    }
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

  void route(HttpRequest request) {
    HttpMethod method = HttpMethod.fromString(request.method);
    Route route = registeredRoute(method, request.uri);
    route.callBack(request);
  }

  Route _retrieveRouteRegisteredForHttpMethod(List<Route> routes, Uri requestUri) {
    List<String> pathElements = requestUri.pathSegments;
    for (int i = 0; i < routes.length; i++) {
      if(_isPathMatching(routes[i].path.pathSegments, pathElements)) {
        return routes[i];
      }
    }
    return null;
  }

  bool _isPathMatching(List<String> base, List<String> compare) {
    if (base.length != compare.length) {
      return false;
    }
    for (int i = 0; i < base.length; i ++) {
      if (compare[i].isEmpty) {
        return false;
      } else if (compare[i] != base[i]) {
        if (!base[i].startsWith("{")) {
          return false;
        }
        List<String> dynamicElements = base[i].split(new RegExp("\[{.\}]")).where((s) => s.isNotEmpty).toList();
        if (dynamicElements.length > compare[i].length) {
          return false;
        }
      }
    }
    return true;
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

  void _extractParameters(List<String> pathElements) {
    for (int i = 0; i < pathElements.length; i++) {
      if (pathElements[i].contains("{")) {
        List<String> allElements = pathElements[i].split(new RegExp("\[{.\}]")).where((s) => s.isNotEmpty).toList();
        if (pathElements[i].contains("?")) {
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
