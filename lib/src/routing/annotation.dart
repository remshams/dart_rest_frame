library restframework.annotation;

import "package:restFramework/src/utils/enums.dart";

class RequestBody {

  const RequestBody();

}

class RestResource {
  final String path;

  const RestResource(this.path);
}

class RestMethod {
  final String path;
  final HttpMethod method;

  const RestMethod(this.path, this.method);
}

class PathParam {
  final String name;

  const PathParam([this.name]);
}