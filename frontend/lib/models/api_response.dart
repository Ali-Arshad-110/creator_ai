class ApiResponse<T> {
  final T? data;
  final String? errorMessage;
  final String? errorCode;
  final bool isSuccess;

  const ApiResponse.success(this.data)
      : errorMessage = null,
        errorCode = null,
        isSuccess = true;

  const ApiResponse.error(this.errorMessage, {this.errorCode})
      : data = null,
        isSuccess = false;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json) fromJsonT,
  ) {
    if (json['detail'] != null) {
      return ApiResponse.error(
        json['detail'] as String,
        errorCode: json['error_code'] as String?,
      );
    }
    return ApiResponse.success(fromJsonT(json));
  }
}
