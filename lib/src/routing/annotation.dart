library restframework.annotation;

import "package:restFramework/src/utils/enums.dart";

class RequestBody {

  const RequestBody();

}

class RestRessource {
  final String path;

  const RestRessource(this.path);
}

class RestMethod {
  final String path;
  final HttpMethod method;

  const RestMethod(this.path, this.method);
}