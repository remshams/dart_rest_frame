library rest_frame.router.test;

import "dart:io";
import "package:rest_frame/rest_frame.dart";
import "package:unittest/unittest.dart";
import "test_utils.dart";
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
    test("Get and body", () {
      router = new Router("");
      void toCall(HttpRequest request, @RequestBody() String body) {
        assert(body.isEmpty);
      };
      router.get("/test", toCall);
      http.get("http://$host:$port/test").then(expectAsync((response) {
        assert(response != null);
        expect(response.statusCode, HttpStatus.OK);
      }));
    });
    test("Delete and body", () {
      router = new Router("");
      void toCall(HttpRequest request, @RequestBody() String body) {
        assert(body.isEmpty);
      };
      router.delete("/test", toCall);
      http.delete("http://$host:$port/test").then(expectAsync((response) {
        assert(response != null);
        expect(response.statusCode, HttpStatus.OK);
      }));
    });
    test("Emtpy body", () {
      router = new Router("");
      void toCall(HttpRequest request, @RequestBody() String body) {
        assert(body.isEmpty);
      };
      router.post("/test", toCall);
      http.post("http://$host:$port/test").then(expectAsync((response) {
        assert(response != null);
        expect(response.statusCode, HttpStatus.OK);
      }));
    });

    test("No RequestBody Type", () {
      router = new Router.fromAnnotation();
      http.post("http://$host:$port/testNoRequestBodyType", body: JSON.encode(new TestObject("12", "test"))).then(expectAsync((response) {
        assert(response != null);
        expect(response.statusCode, HttpStatus.OK);
      }));
    });
  });

}

void main() {
  defineTests();
}