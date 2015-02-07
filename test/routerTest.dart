import "package:unittest/unittest.dart";
import "package:restFramework/src/router.dart";
import "package:mock/mock.dart";
import "dart:io";
import "package:restFramework/src/enums.dart";

class HttpRequestMock extends Mock implements HttpRequest {
  Uri uri;
  String method;

  HttpRequestMock(this.method, this.uri);

  noSuchMethod(i) => super.noSuchMethod(i);
}

void defineTests() {
  group("Routes", () {
    test("getRouteWithoutParameters", () {
      Router router = new Router("/stocks");
      Router bondRouter = router.child("/bonds");
      bool called = false;
      Function getFunction = (HttpRequest request) {
        called = true;
      };
      router.get("/bla", getFunction);
      router.get("/{id}/test", getFunction);
      bondRouter.get("/test{?id}", getFunction);
      HttpRequest request = new HttpRequestMock(HttpMethod.get.toString(), Uri.parse("/stocks/bonds/test"));
      router.route(request);
      assert(called);
    });
  });
}

void main() {
  defineTests();
}