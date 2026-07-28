class ApiException implements Exception {
  final String? message;
  final String? prefix;

  ApiException([this.message, this.prefix]);

  @override
  String toString() {
    var text = "${prefix ?? ''}${message ?? ''}".trim();
    text = text.replaceAll(RegExp(r'^(Exception:\s*)+'), '');
    text = text.replaceAll(RegExp(r'(Communication Error:\s*)+'), '');
    text = text.replaceAll(RegExp(r'(Server Error:\s*)+'), '');
    text = text.replaceAll(RegExp(r'(API Not Responding:\s*)+'), '');
    text = text.trim();

    final lower = text.toLowerCase();
    if (lower.contains('socketexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('connection refused')) {
      return 'Please check your internet connection and try again.';
    }
    if (lower.contains('timeoutexception') || lower.contains('timed out')) {
      return 'The server is taking too long to respond. Please try again.';
    }
    if (lower.contains('formatexception') ||
        lower.contains('unexpected character') ||
        lower.contains('invalid server response')) {
      return 'We received an invalid response. Please refresh and try again.';
    }
    if (lower.contains('unknown column') ||
        lower.contains('doesn\'t exist') ||
        lower.contains('sqlstate') ||
        lower.contains('database')) {
      return 'This service is being updated. Please try again shortly.';
    }
    if (lower == 'error: 404' || lower.contains('not found (404)')) {
      return 'This service is currently unavailable. Please try again later.';
    }
    if (lower.contains('request failed') ||
        lower.contains('failed to load') ||
        lower.contains('could not complete')) {
      return 'We could not complete this request. Please try again.';
    }
    if (lower == 'server error' ||
        lower == 'error: 500' ||
        lower.contains('internal server error')) {
      return 'Server is temporarily unavailable. Please try again shortly.';
    }
    if (text.isEmpty) return 'Something went wrong. Please try again.';
    return text;
  }
}

class FetchDataException extends ApiException {
  FetchDataException([String? message])
    : super(message, "Communication Error: ");
}

class BadRequestException extends ApiException {
  BadRequestException([String? message]) : super(message, "");
}

class UnauthorisedException extends ApiException {
  UnauthorisedException([String? message]) : super(message, "Unauthorised: ");
}

class InvalidInputException extends ApiException {
  InvalidInputException([String? message]) : super(message, "Invalid Input: ");
}

class ApiNotRespondingException extends ApiException {
  ApiNotRespondingException([String? message])
    : super(message, "API Not Responding: ");
}

class ApiInternalException extends ApiException {
  ApiInternalException([String? message]) : super(message, "Server Error: ");
}
