library restframework.router.test;

import "dart:io";
import "package:restFramework/src/routing/router.dart";
import "package:unittest/unittest.dart";
import "../test_utils.dart";
import "package:restFramework/src/routing/annotation.dart";
import "package:http/http.dart" as http;
import "dart:convert";


void defineTests() {
  InternetAddress hostServer = InternetAddress.LOOPBACK_IP_V4;
  String host = hostServer.host;
  int port = 9000;
  HttpServer serverInstance;
  Router router;


  setUp(() {
    print("Server start");
    HttpServer.bind(hostServer, port).then((HttpServer server) {
      serverInstance = server;
      server.listen((HttpRequest request) {
        router.route(request);
      });
    });
  });

  tearDown(() {
    print("Server shutdown");
    serverInstance.close();
  });

  group("RequestBody", () {
    test("Callback function with Annotation", () {
      router = new Router("");
      TestObject reference = new TestObject("12", "test");
      void toCall(HttpRequest request, @RequestBody() TestObject body) {
        expect(body, equals(reference));
      };
      router.post("/test", toCall);
      http.post("http://$host:$port/test", body: JSON.encode(reference)).then(expectAsync((response) {
        assert(response != null);
        expect(response.statusCode, HttpStatus.OK);
      }));
    });

    test("Callback function without Annotation", () {
      router = new Router("");
      TestObject reference = new TestObject("12", "test");
      void toCall(HttpRequest request) {
        UTF8.decodeStream(request).then(expectAsync((body) {
          expect(new TestObject.fromJson(JSON.decode(body)), equals(reference));
        }));
      };
      router.post("/test", toCall);
      http.post("http://$host:$port/test", body: JSON.encode(reference)).then(expectAsync((response) {
        assert(response != null);
        expect(response.statusCode, HttpStatus.OK);
      }));
    });

    test("Callback function with Body as String", () {
      router = new Router("");
      TestObject reference = new TestObject("12", "test");
      void toCall(HttpRequest request, @RequestBody() String body) {
          expect(new TestObject.fromJson(JSON.decode(body)), equals(reference));
      };
      router.post("/test", toCall);
      http.post("http://$host:$port/test", body: JSON.encode(reference)).then(expectAsync((response) {
        assert(response != null);
        expect(response.statusCode, HttpStatus.OK);
      }));
    });

    test("Callback function with Body as Integer", () {
      router = new Router("");
      void toCall(HttpRequest request, @RequestBody() String body) {
        expect(4, equals(int.parse(body)));
      };
      router.post("/test", toCall);
      http.post("http://$host:$port/test", body: JSON.encode(4)).then(expectAsync((response) {
        assert(response != null);
        expect(response.statusCode, HttpStatus.OK);
      }));
    });
  });

}

void main() {
  defineTests();
}