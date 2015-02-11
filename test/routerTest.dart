import "package:unittest/unittest.dart";
import "package:restFramework/src/router.dart";
import "package:mock/mock.dart";
import "dart:io";
import "package:restFramework/src/enums.dart";


// TODO Suuport writing response
// japhr.blogspot.de/2013/07/mocking-httprequest-dumb-way-in-dart.html
class HttpRequestMock extends Mock implements HttpRequest {
  Uri uri;
  String method;

  HttpRequestMock(this.method, this.uri) {

  }

  noSuchMethod(i) => super.noSuchMethod(i);


}

class TestObject {
  String id;
  String name;

  TestObject(this.id, this.name);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = new Map<String, dynamic>();
    json["id"] = id;
    json["name"] = name;
    return json;
  }

  noSuchMethod(i) => super.noSuchMethod(i);
}

void defineTests() {
  group("Routes", () {
    test("getRouteWithoutParameters", () {
      Router router = new Router("/stocks");
      Router bondRouter = router.child("/bonds");
      bool called = false;
      TestObject toCallFunction(HttpRequest request, String id, String name) {
        called = true;
        return new TestObject("12", "Test");
      };
      String notToCallFunction(HttpRequest request) {
        called = false;
        return "wrong";
      };
      router.get("/bla", notToCallFunction);
      router.get("/{id}/test", notToCallFunction);
      bondRouter.get("/test{?id}{?name}", toCallFunction);
      HttpRequest request = new HttpRequestMock(HttpMethod.get.toString(), Uri.parse("/stocks/bonds/test?id=12&name=test"));
      router.route(request);
      assert(called);
    });
    test("getRouteWithParameters", () {
      Router router = new Router("/stocks");
      Router bondRouter = router.child("/bonds");
      bool called = false;
      Function getFunction = (HttpRequest request, String id) {
        called = true;
        return "test";
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