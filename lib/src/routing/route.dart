library restframework.route;

import "package:restFramework/src/utils/utils.dart";
import "dart:io";
import 'dart:mirrors';
import "package:restFramework/src/routing/annotation.dart";

class Route {
  RestPath path;
  Map<HttpHeaders, String> header;
  AbstractRestMethod method;

  Route(String path, ClosureMirror restClosure) {
    this.path = new RestPath(path);
    method = new RestClosure(restClosure);
  }

  Route.fromRestClass(String path, MethodMirror restMethod) {
    this.path = new RestPath(path);
    method = new RestClassMethod(restMethod);
    _processRestMethodParameters(method.parameters, this.path);
  }

  /**
   * Adds queryParameter names from PathParam Annotation to RestPath
   */
  void _processRestMethodParameters(List<MethodParameter> methodParameters, RestPath restPath) {
    for (MethodParameter currentParameter in methodParameters) {
      if (currentParameter.isPathParam) {
        restPath.queryParameters.add(currentParameter.pathParamName);
      }
    }
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
      List<String> elements = new List<String>();
      RegExp exp = new RegExp(r"(\{\?\w+\})");
      Iterable<Match> matcher = exp.allMatches(pathElements[i]);
      if (matcher.isNotEmpty) {
        for (Match currentMatch in matcher) {
          String currentMatcherElement = currentMatch.group(0);
          // Extract value {?id} --> id
          elements.add(currentMatcherElement.substring(2, currentMatcherElement.length - 1));
        }
        // Remove query params from last element
        pathElements[i] = pathElements[i].split(new RegExp(r"(\{\?\w+\})"))[0];
        queryParameters.addAll(elements);
      }
      elements.clear();
      // Check if last element is an url param
      exp = new RegExp(r"(\{\w+\})");
      matcher = exp.allMatches(pathElements[i]);
      if (matcher.isNotEmpty) {
        for (Match currentMatch in matcher) {
          String currentMatcherElement = currentMatch.group(0);
          elements.add(currentMatcherElement.substring(1, currentMatcherElement.length - 1));
        }
        parameters[i] = new Set.from(elements);
      }
      // Remove element if last element contained just query params
      if (pathElements[i].isEmpty) {
        pathElements.removeAt(i);
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
  bool isPathParam = false;
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
        isPathParam = true;
        // Store name of PathParam for later use
        pathParamName = currentAnnotationMirror.getField(#name).reflectee;
        restAnnotations.add(currentAnnotationMirror);
      }
    });
  }
}