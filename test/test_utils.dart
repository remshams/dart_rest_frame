library rest_frame.router.test;

import "package:unittest/unittest.dart";
import "dart:convert";
import "package:rest_frame/rest_frame.dart";
import "dart:io";

/**
 * Object for testing object parsing
 */
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

class TestErrorHandler extends ErrorHandler {

  void handleError(HttpRequest request, e) {
    if (e is TypeError) {
      request.response.statusCode = HttpStatus.BAD_REQUEST;
    } else {
      request.response.statusCode = HttpStatus.INTERNAL_SERVER_ERROR;
    }
    request.response.write("Failure");
    request.response.close();
  }
}


/**
 * Test class for testing method passing (Closures)
 */
class TestRestClass {

  TestObject perform(@RequestBody() TestObject object) {
    return object;
  }

  static TestObject performStatic(@RequestBody() TestObject object) {
    return object;
  }
}

TestObject performGlobal(@RequestBody() TestObject object) {
  return object;
}

@RestResource("/")
class RestClassAnnotations {

  @RestMethod(HttpMethod.get, "test")
  void testGet() {

  }

  @RestMethod(HttpMethod.get, "testParams{?id}{?name}")
  TestObject testGetWithParams(String id, String name) {
    return new TestObject(id, name);
  }

  @RestMethod(HttpMethod.get, "{id}/testUrlParams")
  TestObject testGetWithUrlParams(String id) {
    return new TestObject(id, null);
  }

  @RestMethod(HttpMethod.get, "{id}/testUrlAndPathParams{?name}")
  TestObject testGetWithUrlAndPathParams(String id, String name) {
    return new TestObject(id, name);
  }

  @RestMethod(HttpMethod.post, "test")
  TestObject testPost(@RequestBody() TestObject object) {
    return object;
  }

  @RestMethod(HttpMethod.put, "test")
  TestObject testPut(HttpRequest request, @RequestBody() TestObject object) {
    request.response.statusCode = HttpStatus.CREATED;
    return object;
  }

  @RestMethod(HttpMethod.delete, "test/{id}")
  void testDelete(String id) {

  }

  @RestMethod(HttpMethod.post, "testEmptyBody")
  TestObject testEmptyBody(@RequestBody() TestObject body) {
    return body;
  }

  @RestMethod(HttpMethod.post, "testNoRequestBodyType")
  void testNoRequestBodyType(@RequestBody() body) {

  }

}

@RestResource("/paramAnnotation/")
class RestClassParamAnnotation {

  @RestMethod(HttpMethod.get, "testNoName")
  TestObject testNoName(@PathParam() String id) {
    return new TestObject(id, null);
  }

  @RestMethod(HttpMethod.get, "testAnnotationAndString{?name}")
  TestObject testAnnotationAndString(@PathParam() String id, @PathParam("nameAnnotation") String name) {
    return new TestObject(id, name);
  }

  @RestMethod(HttpMethod.get, "testParamSameName")
  TestObject testParamSameName(@PathParam("id") String id) {
    return new TestObject(id, null);
  }

  @RestMethod(HttpMethod.get, "testParamDifferentName")
  TestObject testParamDifferentName(@PathParam("myId") String idOfObject) {
    return new TestObject(idOfObject, null);
  }

  @RestMethod(HttpMethod.get, "testParamNotProvided")
  TestObject testParamNotProvided(@PathParam("Id") String id) {
    return new TestObject(id, null);
  }

  @RestMethod(HttpMethod.post, "testParamMixed")
  TestObject testParamMixed(@PathParam("id") String id, int value, @RequestBody() TestObject object) {
    object.id = id;
    object.value = value;
    return object;
  }

  @RestMethod(HttpMethod.get, "testParamDuplicate")
  TestObject testParamDuplicate(@PathParam("id") @PathParam("id2") String id) {
    return new TestObject(id, null);
  }

}

@RestResource()
class RestResourceResourceNoPath {

  @RestMethod(HttpMethod.get, "/testResourceNoPath")
  void testResourceNoPath() {

  }

}

@RestResource("testMethodNoPath")
class RestResourceMethodNoPath {

  @RestMethod(HttpMethod.get)
  void testMethodNoPath() {

  }

}

