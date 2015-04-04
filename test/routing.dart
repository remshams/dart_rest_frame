import "package:unittest/unittest.dart";
import "package:rest_frame/rest_frame.dart";
import "dart:io";
import "dart:convert";
import "package:http/http.dart" as http;
import "test_utils.dart";






void defineTests() {
  InternetAddress hostServer = InternetAddress.LOOPBACK_IP_V4;
  String host = hostServer.host;
  int port = 9000;
  HttpServer serverInstance;
  Router router;


  setUp(()  {
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
  group("Routes", () {

    group("Basic Param tests", () {
      test("RoutesQueryParams", () {
        router = new Router("/stocks");
        TestObject reference = new TestObject("12", "test");

        TestObject toCall(HttpRequest request, String id, String name, int value, bool isTrue, num numberValue, double doubleValue) {
          return new TestObject(id, name, value, isTrue, doubleValue, numberValue);
        }
        ;
        router.get(toCall, "/bonds{?id}{?name}{?value}{?isTrue}");
        router.get(() {}, "/{id}/test");
        http.get("http://$host:$port/stocks/bonds?id=12&name=test&value=26&isTrue=true&doubleValue=10.5&numberValue=46").then(expectAsync((response) {
          assert(response != null);
          expect(response.statusCode, HttpStatus.OK);
          TestObject result = new TestObject.fromJson(JSON.decode(response.body));
          expect(result, equals(new TestObject("12", "test", 26, true, 10.5, 46)));
        }));
        http.get("http://$host:$port/stocks/bonds").then(expectAsync((response) {
          assert(response != null);
          expect(response.statusCode, HttpStatus.OK);
          TestObject result = new TestObject.fromJson(JSON.decode(response.body));
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
        }
        ;

        router.get(toCall, "/bonds/{id}");
        router.get(toCall, "/{id}/bonds");
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
        }
        ;

        router.get(toCall, "/{id}/bonds{?name}");
        router.get(toCall, "/{id}/bonds{?name}{?id}");
        router.get(toCall, "/{id}{?name}");
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

      test("RoutesSeverURLParamsMappedToOneSegment", () {
        router = new Router("/stocks");

        TestObject toCall(HttpRequest request, String id, String name) {
          return new TestObject(id, name);
        }
        ;

        router.get(toCall, "/{id}{name}/bonds");
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

      test("Method and UrlParameter Mismatch", () {
        router = new Router("");

        void toCall(String id, String name) {

        }

        router.get(toCall, "/test");
        http.get("http://$host:$port/test").then(expectAsync((response) {
          assert(response != null);
          expect(response.statusCode, HttpStatus.OK);
        }));
      });
      test("UrlParams in root path", () {
        router = new Router("/stocks/{id}{?value}");
        Router child = router.child("");

        TestObject toCall(String id, String name) {
          return new TestObject(id, name);
        }
        TestObject toCallRoot(String id, String value) {
          return new TestObject(id, value);
        }
        router.get(toCallRoot, "");
        child.get(toCall, "/bonds{?name}");
        http.get("http://$host:$port/stocks/12/bonds?name=right").then(expectAsync((response) {
          assert(response != null);
          expect(response.statusCode, HttpStatus.OK);
          expect(new TestObject.fromJson(JSON.decode(response.body)), equals(new TestObject("12", "right")));
        }));
        http.get("http://$host:$port/stocks/12?value=right").then(expectAsync((response) {
          assert(response != null);
          expect(response.statusCode, HttpStatus.OK);
          expect(new TestObject.fromJson(JSON.decode(response.body)), equals(new TestObject("12", "right")));
        }));
      });
    });


    group("Rout and Url Pattern - Special Cases", () {
      test("RoutesEmtpyRootPath", () {
        router = new Router("");

        TestObject toCall(HttpRequest request, String id, String name) {
          return new TestObject(id, name);
        }
        ;

        router.get(toCall, "/{id}");
        router.get(toCall, "/{?id}");
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
        }
        ;

        router.get(toCall, "{id}");
        router.get(toCall, "{?id}");
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


      test("root without slash", () {
        router = new Router("stocks");

        void toCall(String id, String name) {
        }
        router.get(toCall, "/bonds");
        http.get("http://$host:$port/stocks/bonds").then(expectAsync((response) {
          assert(response != null);
          expect(response.statusCode, HttpStatus.OK);
        }));
      });
      test("method as root without slash", () {
        router = new Router("");

        void toCall(String id, String name) {
        }
        router.get(toCall, "bonds");
        http.get("http://$host:$port/bonds").then(expectAsync((response) {
          assert(response != null);
          expect(response.statusCode, HttpStatus.OK);
        }));
      });
      test("child as root without slash", () {
        router = new Router("");
        Router child = router.child("bonds");

        void toCall(String id, String name) {
        }
        router.get(toCall, "bonds");
        http.get("http://$host:$port/bonds").then(expectAsync((response) {
          assert(response != null);
          expect(response.statusCode, HttpStatus.OK);
        }));
      });
      test("multiple slash", () {
        router = new Router("/stocks//{id}");

        void toCall(String id, String name) {
        }
        router.get(toCall, "///bonds");
        http.get("http://$host:$port/stocks/12/bonds").then(expectAsync((response) {
          assert(response != null);
          expect(response.statusCode, HttpStatus.OK);
        }));
        http.get("http://$host:$port/stocks/12///bonds").then(expectAsync((response) {
          assert(response != null);
          expect(response.statusCode, HttpStatus.OK);
        }));
      });

    });

    group("Optional path parameter", () {
      test("router without path", () {
        router = new Router();
        Router child = router.child("/bonds");
        void toCall(String id, String name) {
        }
        router.get(toCall, "/stocks");
        child.get(toCall);
        http.get("http://$host:$port/bonds/").then(expectAsync((response) {
          assert(response != null);
          expect(response.statusCode, HttpStatus.OK);
        }));
        http.get("http://$host:$port/stocks").then(expectAsync((response) {
          assert(response != null);
          expect(response.statusCode, HttpStatus.OK);
        }));
      });
      test("method without path", () {
        router = new Router("/stocks/{id}{?name}");
        TestObject toCall(String id, String name) {
          return new TestObject(id, name);
        }
        router.get(toCall);
        http.get("http://$host:$port/stocks/12?name=test").then(expectAsync((response) {
          assert(response != null);
          expect(response.statusCode, HttpStatus.OK);
          TestObject result = new TestObject.fromJson(JSON.decode(response.body));
          expect(result, equals(new TestObject("12", "test")));
        }));
      });
      test("child router without path", () {
        router = new Router("/stocks");
        Router child = router.child();
        void toCall(String id, String name) {
        }
        child.get(toCall, "/bonds/");
        http.get("http://$host:$port/stocks/bonds").then(expectAsync((response) {
          assert(response != null);
          expect(response.statusCode, HttpStatus.OK);
        }));
      });
    });
  });

  group("Methods", () {
    test("Get", () {
      router = new Router("/stocks");
      TestObject reference = new TestObject("12", "test");
      TestObject toCall(HttpRequest request, String id, String name) {
        return new TestObject(id, name);
      };
      router.get(toCall, "/bonds");
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
      router.post(toCall, "/bonds");
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
      router.put(toCall, "{?id}");
      router.put(toCall, "/bonds{?id}");
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
      router.delete(toCall, "/stocks");
      router.delete(toCall, "/stocks/bonds/test");
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

  group("HttpCodes", () {
    test("200", () {
      router = new Router("");
      router.get(() {}, "/test");
      http.get("http://$host:$port/test").then(expectAsync((response) {
        expect(response.statusCode, HttpStatus.OK);
      }));
    });
    test("404", () {
      router = new Router("");
      router.get(() {}, "/test");
      http.get("http://$host:$port/tester").then(expectAsync((response) {
        expect(response.statusCode, HttpStatus.NOT_FOUND);
      }));
    });
    test("500", () {
      router = new Router("");
      router.get(() {throw new Exception();}, "/test");
      http.get("http://$host:$port/test").then(expectAsync((response) {
        expect(response.statusCode, HttpStatus.INTERNAL_SERVER_ERROR);
      }));
    });
    test("MethodCode", () {
      router = new Router("");
      router.get((HttpRequest request) {request.response.statusCode = HttpStatus.BAD_REQUEST;}, "/test");
      http.get("http://$host:$port/test").then(expectAsync((response) {
        expect(response.statusCode, HttpStatus.BAD_REQUEST);
      }));
    });
  });

  group("UntypedMethods", () {
    test("Params completely untyped", () {
      router = new Router("");
      TestObject reference = new TestObject("12", "test");
      TestObject toCall(id, name) {
        return new TestObject(id, name);
      };
      router.get(toCall, "/test{?id}{?name}");
      http.get("http://$host:$port/test?id=12&name=test").then(expectAsync((response) {
        assert(response != null);
        expect(response.statusCode, HttpStatus.OK);
        TestObject result = new TestObject.fromJson(JSON.decode(response.body));
        expect(result, equals(new TestObject("12", "test")));
      }));
    });

    test("Params var typed", () {
      router = new Router("");
      TestObject reference = new TestObject("12", "test");
      TestObject toCall(var id, dynamic name) {
        return new TestObject(id, name);
      };
      router.get(toCall, "/test{?id}{?name}");
      http.get("http://$host:$port/test?id=12&name=test").then(expectAsync((response) {
        assert(response != null);
        expect(response.statusCode, HttpStatus.OK);
        TestObject result = new TestObject.fromJson(JSON.decode(response.body));
        expect(result, equals(new TestObject("12", "test")));
      }));
    });

    test("HttpRequest param and dynamic types", () {
      router = new Router("");
      TestObject reference = new TestObject("12", "test");
      TestObject toCall(HttpRequest request, id, name) {
        assert(request != null);
        return new TestObject(id, name);
      };
      router.get(toCall, "/test{?id}{?name}");
      http.get("http://$host:$port/test?id=12&name=test").then(expectAsync((response) {
        assert(response != null);
        expect(response.statusCode, HttpStatus.OK);
        TestObject result = new TestObject.fromJson(JSON.decode(response.body));
        expect(result, equals(new TestObject("12", "test")));
      }));
    });
  });

  group("ClassMethods", () {
    test("Class Method", () {
      router = new Router("");
      TestObject reference = new TestObject("12", "test");
      TestRestClass methodClass = new TestRestClass();
      router.post(methodClass.perform, "/test");
      http.post("http://$host:$port/test", body : JSON.encode(reference)).then(expectAsync((response) {
        assert(response != null);
        expect(response.statusCode, HttpStatus.OK);
        TestObject result = new TestObject.fromJson(JSON.decode(response.body));
        expect(result, equals(new TestObject("12", "test")));
      }));
    });

    test("Static Class Method", () {
      router = new Router("");
      TestObject reference = new TestObject("12", "test");
      router.post(TestRestClass.performStatic, "/test");
      http.post("http://$host:$port/test", body : JSON.encode(reference)).then(expectAsync((response) {
        assert(response != null);
        expect(response.statusCode, HttpStatus.OK);
        TestObject result = new TestObject.fromJson(JSON.decode(response.body));
        expect(result, equals(new TestObject("12", "test")));
      }));
    });
    test("Global method", () {
      router = new Router("");
      TestObject reference = new TestObject("12", "test");
      router.post(performGlobal, "/test");
      http.post("http://$host:$port/test", body : JSON.encode(reference)).then(expectAsync((response) {
        assert(response != null);
        expect(response.statusCode, HttpStatus.OK);
        TestObject result = new TestObject.fromJson(JSON.decode(response.body));
        expect(result, equals(new TestObject("12", "test")));
      }));
    });
  });

  group("miscellaneous", () {
    test("Reponse already closed", () {
      router = new Router("");
      TestObject toCall(HttpRequest request, id, name) {
        assert(request != null);
        request.response.write(JSON.encode(new TestObject("16", "test2")));
        request.response.close();
        return new TestObject("12", "test");
      };
      router.get(toCall, "/test");
      http.get("http://$host:$port/test").then(expectAsync((response) {
        assert(response != null);
        expect(response.statusCode, HttpStatus.OK);
        expect(new TestObject.fromJson(JSON.decode(response.body)), equals(new TestObject("16", "test2")));
      }));
    });
    test("Error Handler", () {
      router = new Router("");
      router.get(() {throw new TypeError();}, "/test");
      router.registerErrorHandler(new TestErrorHandler());
      http.get("http://$host:$port/test").then(expectAsync((response) {
        expect(response.statusCode, HttpStatus.BAD_REQUEST);
        expect(response.body, equals("Failure"));
      }));
    });
  });
}

void main() {
  defineTests();
}