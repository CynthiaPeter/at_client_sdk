import 'package:at_client/src/response/response.dart';
import 'package:at_client/src/response/response_parser.dart';

/// The default implementation of [ResponseParser]
class DefaultResponseParser implements ResponseParser {
  /// Returns Response object which contains response or error based on the result.
  /// @param responseString - response coming from secondary server
  /// @returns Response
  @override
  Response parse(String responseString) {
    var response = Response();
    // if responseString starts with data: will call parseSuccessResponse
    if (responseString.startsWith('data:')) {
      parseSuccessResponse(responseString, response);
      // if responseString starts with data: will call parseFailureResponse
    } else if (responseString.startsWith('error:')) {
      parseFailureResponse(responseString, response);
    } else {
      response.response = responseString;
    }
    return response;
  }

  /// Remove data: in responseString and set remaining string to response in Response object
  /// @param responseString - response coming from secondary server
  /// @param response - Response object from parse method
  /// @returns void
  void parseSuccessResponse(String responseString, Response response) {
    response.response = responseString.replaceFirst('data:', '');
  }

  /// Remove error: in responseString and extract Error code and error response if any
  /// set isError to true
  /// set errorCode and errorDescription if any
  /// @param responseString - response coming from secondary server
  /// @param response - Response object from parse method
  /// @returns void
  void parseFailureResponse(String responseString, Response response) {
    // Remove error: from responseString
    responseString = responseString.replaceFirst('error:', '');
    // Set isError to true
    response.isError = true;
    // Find out whether error code exists or not
    if (responseString.isNotEmpty && responseString.startsWith('AT')) {
      response.errorCode = (responseString.split(':')[0]);
      response.errorDescription = (responseString.split(':').length > 1)
          ? responseString.split(':')[1]
          : '';
    } else {
      response.errorDescription = responseString;
    }
  }
}
