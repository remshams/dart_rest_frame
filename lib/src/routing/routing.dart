library restframework.routing;

import "package:restFramework/src/routing/route.dart";

/**
 * Retrieve route for request and request method
 */
Route retrieveRouteRegisteredForHttpMethod(List<Route> routes, Uri requestUri) {
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