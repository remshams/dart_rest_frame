import "package:unittest/unittest.dart";
import "package:restFramework/src/router.dart";
import "dart:io";
import "dart:convert";
import "package:http/http.dart" as http;


class TestObject implements Matcher{
  String id;
  String name;
  int value;
  bool isTrue;
  double doubleValue;
  num numberValue;

  TestObject(this.id, this.name, [this.value, this.isTrue, this.doubleValue, this.numberValue]);

  TestObject.fromJson(Map<String, dynamic> json) {
    this.id = json["id"];
    this.name = json["name"];
    this.value = json["value"];
    this.isTrue = json["isTrue"];
    this.doubleValue = json["doubleValue"];
    this.numberValue = json["numberValue"];
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = new Map<String, dynamic>();
    json["id"] = id;
    json["name"] = name;
    json["value"] = value;
    json["isTrue"] = isTrue;
    json["doubleValue"] = this.doubleValue;
    json["numberValue"] = this.numberValue;
    return json;
  }

  bool matches(TestObject item, Map matchsState) {
    return item.id == this.id && item.name == this.name && item.value == this.value && item.isTrue == this.isTrue
            && item.numberValue == this.numberValue && item.doubleValue == this.doubleValue;
  }

  Description describe(Description description) {
    description.add(JSON.encode(this));
    return description;
  }


  noSuchMethod(i) => super.noSuchMethod(i);
}



void defineTests() {
  String host = InternetAddress.LOOPBACK_IP_V4.host;
  int port = 9000;
  HttpServer serverInstance;
  Router router;


  setUp(()  {
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


    test("RoutesQueryParams", () {
      router = new Router("/stocks");
      TestObject reference = new TestObject("12", "test");
      TestObject toCall(HttpRequest request, String id, String name, int value, bool isTrue, num numberValue, double doubleValue) {
        return new TestObject(id, name, value, isTrue, doubleValue, numberValue);
      };
      router.get("/bonds{?id}{?name}{?value}{?isTrue}", toCall);
      router.get("/{id}/test", () {});
      http.get("http://$host:$port/stocks/bonds?id=12&name=test&value=26&isTrue=true&doubleValue=10.5&numberValue=46").then(expectAsync((response) {
        assert(response != null);
        expect(response.statusCode, HttpStatus.OK);
        TestObject result = new TestObject.fromJson(JSON.decode(response.body));
        expect(result, equals(new TestObject("12", "test", 26, true, 10.5, 46)));
      }));
      http.get("http://$host:$port/stocks/bonds").then(expectAsync((response) {
        assert(response != null);
        TestObject result = new TestObject.fromJson(JSON.decode(response.body));
        expect(response.statusCode, HttpStatus.OK);
        expect(result, equals(new TestObject(null, null)));
      }));
      http.get("http://$host:$port/stocks/12").then(expectAsync((response) {
        assert(response != null);
        expect(response.statusCode, HttpStatus.NOT_FOUND);
      }));

    });

    test("RoutesUrlParams", () {
      router = new Router("/stocks");
      TestObject toCall(HttpRequest request, String id, String name) {
        return new TestObject(id, name);
      };

      router.get("/bonds/{id}", toCall);
      router.get("/{id}/bonds", toCall);
      http.get("http://$host:$port/stocks/bonds/12").then(expectAsync((response) {
        assert(response != null);
        expect(response.statusCode, HttpStatus.OK);
        TestObject result = new TestObject.fromJson(JSON.decode(response.body));
        expect(result, equals(new TestObject("12", null)));
      }));
      http.get("http://$host:$port/stocks/14/bonds").then(expectAsync((response) {
        assert(response != null);
        expect(response.statusCode, HttpStatus.OK);
        TestObject result = new TestObject.fromJson(JSON.decode(response.body));
        expect(result, equals(new TestObject("14", null)));
      }));
      http.get("http://$host:$port/stocks/16/bonds?name=20").then(expectAsync((response) {
        assert(response != null);
        expect(response.statusCode, HttpStatus.OK);
        TestObject result = new TestObject.fromJson(JSON.decode(response.body));
        expect(result, equals(new TestObject("16", "20")));
      }));

    });

    test("RoutesUrlParamsAndQueryParams", () {
      router = new Router("/stocks");
      TestObject toCall(HttpRequest request, String id, String name) {
        return new TestObject(id, name);
      };

      router.get("/{id}/bonds{?name}", toCall);
      router.get("/{id}/bonds{?name}{?id}", toCall);
      router.get("/{id}{?name}", toCall);
      http.get("http://$host:$port/stocks/14/bonds").then(expectAsync((response) {
        assert(response != null);
        expect(response.statusCode, HttpStatus.OK);
        TestObject result = new TestObject.fromJson(JSON.decode(response.body));
        expect(result, equals(new TestObject("14", null)));
      }));
      http.get("http://$host:$port/stocks/16/bonds?name=20").then(expectAsync((response) {
        assert(response != null);
        expect(response.statusCode, HttpStatus.OK);
        TestObject result = new TestObject.fromJson(JSON.decode(response.body));
        expect(result, equals(new TestObject("16", "20")));
      }));
      http.get("http://$host:$port/stocks/16/bonds?name=20&id=22").then(expectAsync((response) {
        assert(response != null);
        expect(response.statusCode, HttpStatus.OK);
        TestObject result = new TestObject.fromJson(JSON.decode(response.body));
        expect(result, equals(new TestObject("16", "20")));
      }));
      http.get("http://$host:$port/stocks/16?name=20").then(expectAsync((response) {
        assert(response != null);
        expect(response.statusCode, HttpStatus.OK);
        TestObject result = new TestObject.fromJson(JSON.decode(response.body));
        expect(result, equals(new TestObject("16", "20")));
      }));

    });

    test("RoutesSeverIRLParamsMappedToOneSegment", () {
      router = new Router("/stocks");
      TestObject toCall(HttpRequest request, String id, String name) {
        return new TestObject(id, name);
      };

      router.get("/{id}{name}/bonds", toCall);
      http.get("http://$host:$port/stocks/14test/bonds").then(expectAsync((response) {
        assert(response != null);
        expect(response.statusCode, HttpStatus.OK);
        TestObject result = new TestObject.fromJson(JSON.decode(response.body));
        expect(result, equals(new TestObject("14t", "est")));
      }));
      http.get("http://$host:$port/stocks/1/bonds").then(expectAsync((response) {
        assert(response != null);
        expect(response.statusCode, HttpStatus.OK);
        TestObject result = new TestObject.fromJson(JSON.decode(response.body));
        expect(result, equals(new TestObject(null, null)));
      }));
      http.get("http://$host:$port/stocks/123/bonds").then(expectAsync((response) {
        assert(response != null);
        expect(response.statusCode, HttpStatus.OK);
        TestObject result = new TestObject.fromJson(JSON.decode(response.body));
        expect(result, equals(new TestObject("1", "23")));
      }));
    });

    test("RoutesEmtpyRootPath", () {
      router = new Router("");
      TestObject toCall(HttpRequest request, String id, String name) {
        return new TestObject(id, name);
      };

      router.get("/{id}", toCall);
      router.get("/{?id}", toCall);
      http.get("http://$host:$port/12").then(expectAsync((response) {
        assert(response != null);
        expect(response.statusCode, HttpStatus.OK);
        TestObject result = new TestObject.fromJson(JSON.decode(response.body));
        expect(result, equals(new TestObject("12", null)));
      }));
      http.get("http://$host:$port/?id=12").then(expectAsync((response) {
        assert(response != null);
        expect(response.statusCode, HttpStatus.OK);
        TestObject result = new TestObject.fromJson(JSON.decode(response.body));
        expect(result, equals(new TestObject("12", null)));
      }));
    });

    test("RoutesRoot", () {
      router = new Router("/");
      TestObject toCall(HttpRequest request, String id, String name) {
        return new TestObject(id, name);
      };

      router.get("{id}", toCall);
      router.get("{?id}", toCall);
      http.get("http://$host:$port/12").then(expectAsync((response) {
        assert(response != null);
        expect(response.statusCode, HttpStatus.OK);
        TestObject result = new TestObject.fromJson(JSON.decode(response.body));
        expect(result, equals(new TestObject("12", null)));
      }));
      http.get("http://$host:$port/?id=12").then(expectAsync((response) {
        assert(response != null);
        expect(response.statusCode, HttpStatus.OK);
        TestObject result = new TestObject.fromJson(JSON.decode(response.body));
        expect(result, equals(new TestObject("12", null)));
      }));
    });

  });

  group("Methods", () {
    test("Get", () {
      router = new Router("/stocks");
      TestObject reference = new TestObject("12", "test");
      TestObject toCall(HttpRequest request, String id, String name) {
        return new TestObject(id, name);
      };
      router.get("/bonds", toCall);
      http.get("http://$host:$port/stocks/bonds").then(expectAsync((response) {
        assert(response != null);
        expect(response.statusCode, HttpStatus.OK);
        TestObject result = new TestObject.fromJson(JSON.decode(response.body));
        expect(result.toJson(), equals(new TestObject(null, null).toJson()));
      }));
    });

    test("Post", () {
      router = new Router("/stocks");
      TestObject reference = new TestObject("12", "test");
      void toCall(HttpRequest request, String id, String name) {
        String body;
        UTF8.decodeStream(request).then(expectAsync((data) {
          expect(new TestObject.fromJson(JSON.decode(data)), equals(new TestObject("12", "test")));
        }));
      };
      router.post("/bonds", toCall);
      http.post("http://$host:$port/stocks/bonds", body: JSON.encode(new TestObject("12", "test"))).then(expectAsync((response) {
        assert(response != null);
        expect(response.statusCode, HttpStatus.OK);
      }));
    });

    test("Put", () {
      router = new Router("/");
      void toCall(HttpRequest request, String id, String name) {
        String body;
        expect(id, equals("12"));
        UTF8.decodeStream(request).then(expectAsync((data) {
          expect(new TestObject.fromJson(JSON.decode(data)), equals(new TestObject("12", "test")));
        }));
      };
      router.put("{?id}", toCall);
      router.put("/bonds{?id}", toCall);
      http.put("http://$host:$port/bonds?id=12", body: JSON.encode(new TestObject("12", "test"))).then(expectAsync((response) {
        assert(response != null);
        expect(response.statusCode, HttpStatus.OK);
      }));
      http.put("http://$host:$port/?id=12", body: JSON.encode(new TestObject("12", "test"))).then(expectAsync((response) {
        assert(response != null);
        expect(response.statusCode, HttpStatus.OK);
      }));
    });

    test("Delete", () {
      router = new Router("");
      void toCall(HttpRequest request, String id, String name) {

      };
      router.delete("/stocks", toCall);
      router.delete("/stocks/bonds/test", toCall);
      http.delete("http://$host:$port/stocks").then(expectAsync((response) {
        assert(response != null);
        expect(response.statusCode, HttpStatus.OK);
      }));
      http.delete("http://$host:$port/stocks/bonds/test").then(expectAsync((response) {
        assert(response != null);
        expect(response.statusCode, HttpStatus.OK);
      }));
    });
  });
}

void main() {
  defineTests();
}