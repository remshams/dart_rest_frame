library rest_frame.utils;


class Utils {

  /**
   * Removes empty elements from list
   */
  static List<dynamic> removeEmptyElementsFromList(List<dynamic> list) {
    return list.where((s) => s.isNotEmpty).toList();
  }

  /**
   * Combines list of string elements to a single string
   */
  static String combineSegments(List<String> segments) {
    String result = "";
    for (String currentSegment in segments) {
      if (currentSegment != null && currentSegment.isNotEmpty) {
        result += currentSegment;
      }
    }
    return result;
  }
}