library rest_frame.routing;

import "package:rest_frame/src/route.dart";
import "dart:mirrors";
import "package:rest_frame/src/annotations/annotation.dart";
import "package:rest_frame/src/utils/utils.dart";

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
  // Path segments of registered routes are stored without empty elements
  // e.g. in case route contains several slashes (/stocks///bonds)
  // removeEmptyElementsFromList removes these elements from list
  List<String> compare = Utils.removeEmptyElementsFromList(comparePath.pathSegments);
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
 * Creates routes from restClass
 */
Iterable<DeclarationMirror> retrieveRestMethods(ClassMirror restClass) {
  Iterable<DeclarationMirror> restMethods = restClass.declarations.values.where((DeclarationMirror declaration) {
    if (declaration is MethodMirror) {
      for (InstanceMirror annotation in declaration.metadata) {
        return annotation.type == reflectClass(RestMethod);
      }
    }
    return false;
  });
  return restMethods;
}

/**
 * Retrieves all classes with [RestResource] Annotation
 */
List<ClassMirror> retrieveRestClassesForIsolate() {
  List<ClassMirror> restResourceClasses = new List<ClassMirror>();
  MirrorSystem mirrorSystem = currentMirrorSystem();
  mirrorSystem.libraries.values.forEach((currentLibraryMirror) {
    currentLibraryMirror.declarations.values.forEach((currentDeclarationMirror) {
      if(currentDeclarationMirror is ClassMirror) {
        ClassMirror classMirror = currentDeclarationMirror as ClassMirror;
        classMirror.metadata.forEach((currentMetaDataMirror) {
          // Check if current class is a rest resource
          if(currentMetaDataMirror.type == reflectClass(RestResource)) {
            //_path = _createPath(metadata.getField(#path).reflectee);
            restResourceClasses.add(classMirror);
          }
        });
      }
    });
  });
  return restResourceClasses;
}