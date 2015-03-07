library restframework.route;

import "package:restFramework/src/utils/utils.dart";
import "dart:io";
import 'dart:mirrors';
import "package:restFramework/src/routing/annotation.dart";

class Route {
  RestPath path;
  Map<HttpHeaders, String> header;
  AbstractRestMethod method;

  Route(this.path, ClosureMirror restClosure) {
    method = new RestClosure(restClosure);
  }

  Route.fromRestClass(this.path, MethodMirror restMethod) {
    method = new RestClassMethod(restMethod);
  }

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

/**
 * Wrapper for function of a specific route
 * Contains the function executed for a specific route
 */
abstract class AbstractRestMethod {
  MethodMirror function;
  List<MethodParameter> parameters;

  AbstractRestMethod(this.function) {
    parameters = new List<MethodParameter>();
    _extractParameters();
  }

  dynamic invoke(List<dynamic> invokeParameters);

  void _extractParameters() {
    function.parameters.forEach((currentParameter) {
      parameters.add(new MethodParameter(currentParameter));
    });
  }

}
/**
 * Wrapper for a provided closure
 */
class RestClosure extends AbstractRestMethod {
  ClosureMirror closure;

  RestClosure(ClosureMirror closure) : super(closure.function) {
    this.closure = closure;
  }

  dynamic invoke(List<dynamic> invokeParameters) {
    return closure.apply(invokeParameters).reflectee;
  }
}
/**
 * Wrapper for a provided class method
 */
class RestClassMethod extends AbstractRestMethod {
  MethodMirror method;
  InstanceMirror classInstance;

  RestClassMethod(MethodMirror method, [this.classInstance]) : super(method) {
    this.method = method;
  }

  dynamic invoke(List<dynamic> invokeParameters) {
    ClassMirror owningClass = method.owner;
    if (method.isStatic) {
      return owningClass.invoke(method.simpleName, invokeParameters).reflectee;
    } else {
      InstanceMirror classInstance = owningClass.newInstance(new Symbol(""), []);
      return classInstance.invoke(method.simpleName, invokeParameters).reflectee;
    }
  }
}

class MethodParameter {
  ParameterMirror parameterMirror;
  Set<InstanceMirror> restAnnotations;
  String pathParamName;
  bool isRequestBodyParameter = false;
  bool isHttpRequestParameter = false;

  MethodParameter(this.parameterMirror) {
    restAnnotations = new Set<InstanceMirror>();
    isHttpRequestParameter = parameterMirror.type == reflectType(HttpRequest);
    _extractRestAnnotations();
  }

  void _extractRestAnnotations() {
    // Only add rest relevant annotation
    parameterMirror.metadata.forEach((currentAnnotationMirror) {
      if (currentAnnotationMirror.type == reflectType(RequestBody)) {
        isRequestBodyParameter = true;
        restAnnotations.add(currentAnnotationMirror);
      } else if (currentAnnotationMirror.type == reflectType(PathParam)) {
        // Store name of PathParam for later use
        pathParamName = currentAnnotationMirror.getField(#name).reflectee;
        restAnnotations.add(currentAnnotationMirror);
      }
    });
  }
}