library restframework.route;

import "package:restFramework/src/utils/utils.dart";
import "dart:io";

class Route {
  RestPath path;
  Map<HttpHeaders, String> header;
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
          String oldPathElement = pathElements[i];
          // Replace element with queryParameters by element (e.g.../test{?id}{?name} -> test)
          // Case /{?id} --> last element not a path element
          if (allElements[0].contains("?")) {
            pathElements.removeAt(i);
          } else {
            // Case /{id}{?name}
            if (oldPathElement[0] == "{") {
              pathElements[i] = oldPathElement;
              parameters[i] = new Set.from([allElements[0]]);
              // Case ../test{?id}
            } else {
              pathElements[i] = allElements[0];
            }
          }
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