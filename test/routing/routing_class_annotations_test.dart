library restframework.router.test;

import "package:unittest/unittest.dart";
import "package:restFramework/src/routing/router.dart";
import "../test_utils.dart";
import "package:http/http.dart" as http;
import "dart:convert";
import "dart:io";

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

  group("Standard Routes", () {
    test("Plain rooting", () {
      router = new Router.fromAnnotation();
      http.get("http://$host:$port/test").then(expectAsync((response) {
        assert(response != null);
        expect(response.statusCode, HttpStatus.OK);
      }));
    });

    test("Routing with PathParams", () {
      router = new Router.fromAnnotation();
      http.get("http://$host:$port/12/testUrlParams").then(expectAsync((response) {
        assert(response != null);
        expect(response.statusCode, HttpStatus.OK);
        TestObject result = new TestObject.fromJson(JSON.decode(response.body));
        expect(result, equals(new TestObject("12", null)));
      }));
    });

    test("Routing with Url Params", () {
      router = new Router.fromAnnotation();
      http.get("http://$host:$port/testParams?id=12&name=test").then(expectAsync((response) {
        assert(response != null);
        expect(response.statusCode, HttpStatus.OK);
        TestObject result = new TestObject.fromJson(JSON.decode(response.body));
        expect(result, equals(new TestObject("12", "test")));
      }));
    });

    test("Routing with Url and Path Params", () {
      router = new Router.fromAnnotation();
      http.get("http://$host:$port/12/testUrlAndPathParams?name=test").then(expectAsync((response) {
        assert(response != null);
        expect(response.statusCode, HttpStatus.OK);
        TestObject result = new TestObject.fromJson(JSON.decode(response.body));
        expect(result, equals(new TestObject("12", "test")));
      }));
    });
  });

  group("PathParams Routes", () {

    test("PathParam - no name", () {
      router = new Router.fromAnnotation();
      http.get("http://$host:$port/paramAnnotation/testNoName?id=12").then(expectAsync((response) {
        assert(response != null);
        expect(response.statusCode, HttpStatus.OK);
        TestObject result = new TestObject.fromJson(JSON.decode(response.body));
        expect(result, equals(new TestObject("12", null)));
      }));
    });
    test("PathParam - same name", () {
      router = new Router.fromAnnotation();
      http.get("http://$host:$port/paramAnnotation/testParamSameName?id=12").then(expectAsync((response) {
        assert(response != null);
        expect(response.statusCode, HttpStatus.OK);
        TestObject result = new TestObject.fromJson(JSON.decode(response.body));
        expect(result, equals(new TestObject("12", null)));
      }));
    });
    test("PathParam - different name", () {
      router = new Router.fromAnnotation();
      http.get("http://$host:$port/paramAnnotation/testParamDifferentName?myId=12").then(expectAsync((response) {
        assert(response != null);
        expect(response.statusCode, HttpStatus.OK);
        TestObject result = new TestObject.fromJson(JSON.decode(response.body));
        expect(result, equals(new TestObject("12", null)));
      }));
    });
    test("PathParam - not provided", () {
      router = new Router.fromAnnotation();
      http.get("http://$host:$port/paramAnnotation/testParamNotProvided").then(expectAsync((response) {
        assert(response != null);
        expect(response.statusCode, HttpStatus.OK);
        TestObject result = new TestObject.fromJson(JSON.decode(response.body));
        expect(result, equals(new TestObject(null, null)));
      }));
    });
    test("PathParam - mixed", () {
      router = new Router.fromAnnotation();
      TestObject reference = new TestObject("16", "test", 12);
      http.post("http://$host:$port/paramAnnotation/testParamMixed?id=12&value=12", body : JSON.encode(reference)).then(expectAsync((response) {
        assert(response != null);
        expect(response.statusCode, HttpStatus.OK);
        TestObject result = new TestObject.fromJson(JSON.decode(response.body));
        expect(result, equals(new TestObject("12", "test", 12)));
      }));
    });
    test("PathParam - Annotation and String param mixed", () {
      router = new Router.fromAnnotation();
      http.get("http://$host:$port/paramAnnotation/testAnnotationAndString?id=12&name=wrong&nameAnnotation=right").then(expectAsync((response) {
        assert(response != null);
        expect(response.statusCode, HttpStatus.OK);
        TestObject result = new TestObject.fromJson(JSON.decode(response.body));
        expect(result, equals(new TestObject("12", "right")));
      }));
    });
  });

  group("Rest Methods", () {
    test("Get", () {
      router = new Router.fromAnnotation();
      http.get("http://$host:$port/test").then(expectAsync((response) {
        assert(response != null);
        expect(response.statusCode, HttpStatus.OK);
      }));
    });

    test("Post", () {
      router = new Router.fromAnnotation();
      TestObject reference = new TestObject("12", "test");
      http.post("http://$host:$port/test", body : JSON.encode(reference)).then(expectAsync((response) {
        assert(response != null);
        expect(response.statusCode, HttpStatus.OK);
        TestObject result = new TestObject.fromJson(JSON.decode(response.body));
        expect(result, equals(new TestObject("12", "test")));
      }));
    });

    test("Put", () {
      router = new Router.fromAnnotation();
      TestObject reference = new TestObject("12", "test");
      http.put("http://$host:$port/test", body : JSON.encode(reference)).then(expectAsync((response) {
        assert(response != null);
        expect(response.statusCode, HttpStatus.CREATED);
        TestObject result = new TestObject.fromJson(JSON.decode(response.body));
        expect(result, equals(new TestObject("12", "test")));
      }));
    });

    test("Delete", () {
      router = new Router.fromAnnotation();
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