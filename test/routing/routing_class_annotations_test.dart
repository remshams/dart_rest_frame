library restframework.router.test;

import "package:unittest/unittest.dart";
import "package:restFramework/src/routing/router.dart";
import "../test_utils.dart";
import "package:http/http.dart" as http;
import "dart:convert";
import "dart:io";

void defineTests() {
  String host = InternetAddress.LOOPBACK_IP_V4.host;
  int port = 9000;
  HttpServer serverInstance;
  Router router;


  setUp(() {
    print("Server start");
    HttpServer.bind(host, port).then((HttpServer server) {
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

  group("Routes", () {
    test("Plain rooting", () {
      router = new Router.fromRestClasses();
      http.get("http://$host:$port/test").then(expectAsync((response) {
        assert(response != null);
        expect(response.statusCode, HttpStatus.OK);
      }));
    });

    test("Routing with PathParams", () {
      router = new Router.fromRestClasses();
      http.get("http://$host:$port/12/testUrlParams").then(expectAsync((response) {
        assert(response != null);
        expect(response.statusCode, HttpStatus.OK);
        TestObject result = new TestObject.fromJson(JSON.decode(response.body));
        expect(result, equals(new TestObject("12", null)));
      }));
    });

    test("Routing with Url Params", () {
      router = new Router.fromRestClasses();
      http.get("http://$host:$port/testParams?id=12&name=test").then(expectAsync((response) {
        assert(response != null);
        expect(response.statusCode, HttpStatus.OK);
        TestObject result = new TestObject.fromJson(JSON.decode(response.body));
        expect(result, equals(new TestObject("12", "test")));
      }));
    });

    test("Routing with Url and Path Params", () {
      router = new Router.fromRestClasses();
      http.get("http://$host:$port/12/testUrlAndPathParams?name=test").then(expectAsync((response) {
        assert(response != null);
        expect(response.statusCode, HttpStatus.OK);
        TestObject result = new TestObject.fromJson(JSON.decode(response.body));
        expect(result, equals(new TestObject("12", "test")));
      }));
    });
  });

  group("Rest Methods", () {
    test("Get", () {
      router = new Router.fromRestClasses();
      http.get("http://$host:$port/test").then(expectAsync((response) {
        assert(response != null);
        expect(response.statusCode, HttpStatus.OK);
      }));
    });

    test("Post", () {
      router = new Router.fromRestClasses();
      TestObject reference = new TestObject("12", "test");
      http.post("http://$host:$port/test", body : JSON.encode(reference)).then(expectAsync((response) {
        assert(response != null);
        expect(response.statusCode, HttpStatus.OK);
        TestObject result = new TestObject.fromJson(JSON.decode(response.body));
        expect(result, equals(new TestObject("12", "test")));
      }));
    });

    test("Put", () {
      router = new Router.fromRestClasses();
      TestObject reference = new TestObject("12", "test");
      http.put("http://$host:$port/test", body : JSON.encode(reference)).then(expectAsync((response) {
        assert(response != null);
        expect(response.statusCode, HttpStatus.CREATED);
        TestObject result = new TestObject.fromJson(JSON.decode(response.body));
        expect(result, equals(new TestObject("12", "test")));
      }));
    });

    test("Delete", () {
      router = new Router.fromRestClasses();
      http.delete("http://$host:$port/test/12").then(expectAsync((response) {
        assert(response != null);
        expect(response.statusCode, HttpStatus.OK);
      }));
    });
  });
}

void main() {
  defineTests();
}