library rest_frame.enums;




class HttpMethod {
  final String _value;
  const HttpMethod._internal(this._value);
  toString() => _value;
  static HttpMethod fromString(String httpMethod) {
    if (httpMethod.toLowerCase() == HttpMethod.get.toString().toLowerCase()) {
      return HttpMethod.get;
    } else if (httpMethod.toLowerCase() == HttpMethod.put.toString().toLowerCase()) {
      return HttpMethod.put;
    } else if (httpMethod.toLowerCase() == HttpMethod.post.toString().toLowerCase()) {
      return HttpMethod.post;
    } else if (httpMethod.toLowerCase() == HttpMethod.delete.toString().toLowerCase()) {
      return HttpMethod.delete;
    }
    return null;
  }

  static const get = const HttpMethod._internal('get');
  static const put = const HttpMethod._internal('put');
  static const post = const HttpMethod._internal('Post');
  static const delete = const HttpMethod._internal('delete');
}
