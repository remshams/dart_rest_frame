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
      Function toCallFunction = (HttpRequest request, String id) {
        called = true;
      };
      Function notToCallFunction = (HttpRequest request) {
        called = false;
      };
      router.get("/bla", notToCallFunction);
      router.get("/{id}/test", notToCallFunction);
      bondRouter.get("/test{?id}{?name}", toCallFunction);
      HttpRequest request = new HttpRequestMock(HttpMethod.get.toString(), Uri.parse("/stocks/bonds/test?id=test"));
      router.route(request);
      assert(called);
    });
    test("getRouteWithParameters", () {
      Router router = new Router("/stocks");
      Router bondRouter = router.child("/bonds");
      bool called = false;
      Function getFunction = (HttpRequest request, String id) {
        called = true;
      };
      Function notToCallFunction = (HttpRequest request, String id) {
        called = false;
      };
      router.get("/bla", notToCallFunction);
      router.get("/{id}/test", getFunction);
      bondRouter.get("/test{?id}", notToCallFunction);
      HttpRequest request = new HttpRequestMock(HttpMethod.get.toString(), Uri.parse("/stocks/12/test"));
      router.route(request);
      assert(called);
    });
  });
}

void main() {
  defineTests();
}