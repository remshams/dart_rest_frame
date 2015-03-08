library rest_frame.utils;


class Utils {

  static List<dynamic> removeEmptyElementsFromList(List<dynamic> list) {
    return list.where((s) => s.isNotEmpty).toList();
  }
}