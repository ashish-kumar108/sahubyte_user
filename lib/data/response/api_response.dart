import 'package:sahubyte_user/data/response/status.dart';

class ApiResponse<T> {
  Status status;
  T? data;
  String? message;

  ApiResponse(this.status, this.data, this.message);

  ApiResponse.loading() : status = Status.loading, data = null, message = null;
  ApiResponse.completed(this.data) : status = Status.completed, message = null;
  ApiResponse.error(this.message) : status = Status.error, data = null;

  @override
  String toString() {
    return "Status: $status \n Message: $message \n Data: $data";
  }
}
