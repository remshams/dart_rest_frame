library restframework.router.test;

import "package:unittest/unittest.dart";
import "dart:convert";
import "package:restFramework/src/routing/annotation.dart";
import "package:restFramework/src/utils/enums.dart";
import "dart:io";

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

@RestResource("/")
class TestRestClass {

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

}
