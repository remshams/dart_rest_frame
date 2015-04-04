library rest_frame.annotation;

import "package:rest_frame/src/enums/enums.dart";

class RequestBody {

  const RequestBody();

}

class RestResource {
  final String path;

  const RestResource([this.path]);
}

class RestMethod {
  final String path;
  final HttpMethod method;

  const RestMethod(this.method, [this.path]);
}

class PathParam {
  final String name;

  const PathParam([this.name]);
}