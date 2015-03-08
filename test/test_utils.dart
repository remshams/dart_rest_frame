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

  @RestMethod("test", HttpMethod.get)
  void testGet() {

  }

  @RestMethod("testParams{?id}{?name}", HttpMethod.get)
  TestObject testGetWithParams(String id, String name) {
    return new TestObject(id, name);
  }

  @RestMethod("{id}/testUrlParams", HttpMethod.get)
  TestObject testGetWithUrlParams(String id) {
    return new TestObject(id, null);
  }

  @RestMethod("{id}/testUrlAndPathParams{?name}", HttpMethod.get)
  TestObject testGetWithUrlAndPathParams(String id, String name) {
    return new TestObject(id, name);
  }

  @RestMethod("test", HttpMethod.post)
  TestObject testPost(@RequestBody() TestObject object) {
    return object;
  }

  @RestMethod("test", HttpMethod.put)
  TestObject testPut(HttpRequest request, @RequestBody() TestObject object) {
    request.response.statusCode = HttpStatus.CREATED;
    return object;
  }

  @RestMethod("test/{id}", HttpMethod.delete)
  void testDelete(String id) {

  }

  @RestMethod("testEmptyBody", HttpMethod.post)
  TestObject testEmptyBody(@RequestBody() TestObject body) {
    return body;
  }

  @RestMethod("testNoRequestBodyType", HttpMethod.post)
  void testNoRequestBodyType(@RequestBody() body) {

  }

}

@RestResource("/paramAnnotation/")
class RestClassParamAnnotation {

  @RestMethod("testNoName", HttpMethod.get)
  TestObject testNoName(@PathParam() String id) {
    return new TestObject(id, null);
  }

  @RestMethod("testAnnotationAndString{?name}", HttpMethod.get)
  TestObject testAnnotationAndString(@PathParam() String id, @PathParam("nameAnnotation") String name) {
    return new TestObject(id, name);
  }

  @RestMethod("testParamSameName", HttpMethod.get)
  TestObject testParamSameName(@PathParam("id") String id) {
    return new TestObject(id, null);
  }

  @RestMethod("testParamDifferentName", HttpMethod.get)
  TestObject testParamDifferentName(@PathParam("myId") String idOfObject) {
    return new TestObject(idOfObject, null);
  }

  @RestMethod("testParamNotProvided", HttpMethod.get)
  TestObject testParamNotProvided(@PathParam("Id") String id) {
    return new TestObject(id, null);
  }

  @RestMethod("testParamMixed", HttpMethod.post)
  TestObject testParamMixed(@PathParam("id") String id, int value, @RequestBody() TestObject object) {
    object.id = id;
    object.value = value;
    return object;
  }

  @RestMethod("testParamDuplicate", HttpMethod.get)
  TestObject testParamDuplicate(@PathParam("id") @PathParam("id2") String id) {
    return new TestObject(id, null);
  }

}

