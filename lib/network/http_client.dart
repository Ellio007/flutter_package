import 'dart:io';

import 'package:dio/dio.dart';
import 'app_dio.dart';
import 'default_http_transformer.dart';
import 'http_exception.dart';
import 'http_response.dart';
import 'http_transformer.dart';
import '/utils/sp_utils.dart';

import 'http_config.dart';

class HttpClient {
  late AppDio _dio;

  HttpClient({BaseOptions? options, HttpConfig? dioConfig})
      : _dio = AppDio(options: options, dioConfig: dioConfig);

  Future<HttpResponse> get(String uri,
      {Map<String, dynamic>? queryParameters,
      Options? options,
      CancelToken? cancelToken,
      ProgressCallback? onReceiveProgress,
      HttpTransformer? httpTransformer}) async {
    try {
      Options requestOptions = options ?? Options();

      Map<String, dynamic> _authorization = await _getAuthAndCommonHeader();
      requestOptions = requestOptions.copyWith(headers: _authorization);
      var response = await _dio.get(
        uri,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
      return handleResponse(response, httpTransformer: httpTransformer);
    } on Exception catch (e) {
      return handleException(e);
    }
  }

  Future<HttpResponse> post(String uri,
      {data,
      Map<String, dynamic>? queryParameters,
      Options? options,
      CancelToken? cancelToken,
      ProgressCallback? onSendProgress,
      ProgressCallback? onReceiveProgress,
      HttpTransformer? httpTransformer}) async {
    try {
      Options requestOptions = options ?? Options();

      if (requestOptions.headers == null ||
          !requestOptions.headers!.containsKey("Authorization")) {
        Map<String, dynamic> _authorization = await _getAuthAndCommonHeader();
        requestOptions = requestOptions.copyWith(headers: _authorization);
      }
      var response = await _dio.post(
        uri,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return handleResponse(response, httpTransformer: httpTransformer);
    } on Exception catch (e) {
      return handleException(e);
    }
  }

  Future<HttpResponse> patch(String uri,
      {data,
      Map<String, dynamic>? queryParameters,
      Options? options,
      CancelToken? cancelToken,
      ProgressCallback? onSendProgress,
      ProgressCallback? onReceiveProgress,
      HttpTransformer? httpTransformer}) async {
    try {
      Options requestOptions = options ?? Options();

      Map<String, dynamic> _authorization = await _getAuthAndCommonHeader();
      requestOptions = requestOptions.copyWith(headers: _authorization);
      var response = await _dio.patch(
        uri,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return handleResponse(response, httpTransformer: httpTransformer);
    } on Exception catch (e) {
      return handleException(e);
    }
  }

  Future<HttpResponse> delete(String uri,
      {data,
      Map<String, dynamic>? queryParameters,
      Options? options,
      CancelToken? cancelToken,
      HttpTransformer? httpTransformer}) async {
    try {
      Options requestOptions = options ?? Options();

      Map<String, dynamic> _authorization = await _getAuthAndCommonHeader();
      requestOptions = requestOptions.copyWith(headers: _authorization);
      var response = await _dio.delete(
        uri,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return handleResponse(response, httpTransformer: httpTransformer);
    } on Exception catch (e) {
      return handleException(e);
    }
  }

  Future<HttpResponse> put(String uri,
      {data,
      Map<String, dynamic>? queryParameters,
      Options? options,
      CancelToken? cancelToken,
      HttpTransformer? httpTransformer}) async {
    try {
      Options requestOptions = options ?? Options();

      Map<String, dynamic> _authorization = await _getAuthAndCommonHeader();
      requestOptions = requestOptions.copyWith(headers: _authorization);
      var response = await _dio.put(
        uri,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return handleResponse(response, httpTransformer: httpTransformer);
    } on Exception catch (e) {
      return handleException(e);
    }
  }

  Future<Response> download(String urlPath, savePath,
      {ProgressCallback? onReceiveProgress,
      Map<String, dynamic>? queryParameters,
      CancelToken? cancelToken,
      bool deleteOnError = true,
      String lengthHeader = Headers.contentLengthHeader,
      data,
      Options? options,
      HttpTransformer? httpTransformer}) async {
    try {
      Options requestOptions = options ?? Options();

      Map<String, dynamic> _authorization = await _getAuthAndCommonHeader();
      requestOptions = requestOptions.copyWith(headers: _authorization);
      var response = await _dio.download(
        urlPath,
        savePath,
        onReceiveProgress: onReceiveProgress,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        deleteOnError: deleteOnError,
        lengthHeader: lengthHeader,
        data: data,
        options: data,
      );
      return response;
    } catch (e) {
      throw e;
    }
  }
}

HttpResponse handleResponse(Response? response,
    {HttpTransformer? httpTransformer}) {
  httpTransformer ??= DefaultHttpTransformer.getInstance();

  // ???????????????
  if (response == null) {
    return HttpResponse.failureFromError();
  }

  // token??????
  if (_isTokenTimeout(response.statusCode)) {
    return HttpResponse.failureFromError(
        UnauthorisedException(message: "????????????", code: response.statusCode));
  }
  // ??????????????????
  if (_isRequestSuccess(response.statusCode)) {
    return httpTransformer.parse(response);
  } else {
    // ??????????????????
    return HttpResponse.failure(
        errorMsg: response.statusMessage, errorCode: response.statusCode);
  }
}

HttpResponse handleException(Exception exception) {
  var parseException = _parseException(exception);
  return HttpResponse.failureFromError(parseException);
}

/// ????????????
bool _isTokenTimeout(int? code) {
  return code == 401;
}

/// ????????????
bool _isRequestSuccess(int? statusCode) {
  return (statusCode != null && statusCode >= 200 && statusCode < 300);
}

/// ????????????Token?????????header
Future<Map<String, dynamic>> _getAuthAndCommonHeader() async {
  var headers;
  String accessToken =
      await SpUtils.getPreference(SpUtils.TOKEN_KEY, "") as String;
  if (accessToken.isNotEmpty) {
    headers = {
      'Authorization': 'Bearer $accessToken',
    };
  } else {
    headers = Map();
  }
  return headers;
}

HttpException _parseException(Exception error) {
  if (error is DioError) {
    switch (error.type) {
      case DioErrorType.connectTimeout:
      case DioErrorType.receiveTimeout:
      case DioErrorType.sendTimeout:
        return NetworkException(message: error.error.message);
      case DioErrorType.cancel:
        return CancelException(error.error.message);
      case DioErrorType.response:
        try {
          int? errCode = error.response?.statusCode;
          switch (errCode) {
            case 400:
              return BadRequestException(message: "??????????????????", code: errCode);
            case 401:
              return UnauthorisedException(message: "????????????", code: errCode);
            case 403:
              return BadRequestException(message: "?????????????????????", code: errCode);
            case 404:
              return BadRequestException(message: "?????????????????????", code: errCode);
            case 405:
              return BadRequestException(message: "?????????????????????", code: errCode);
            case 500:
              return BadServiceException(message: "?????????????????????", code: errCode);
            case 502:
              return BadServiceException(message: "???????????????", code: errCode);
            case 503:
              return BadServiceException(message: "???????????????", code: errCode);
            case 505:
              return UnauthorisedException(
                  message: "?????????HTTP????????????", code: errCode);
            default:
              return UnknownException(error.error.message);
          }
        } on Exception catch (_) {
          return UnknownException(error.error.message);
        }

      case DioErrorType.other:
        if (error.error is SocketException) {
          return NetworkException(message: error.message);
        } else {
          return UnknownException(error.message);
        }
      default:
        return UnknownException(error.message);
    }
  } else {
    return UnknownException(error.toString());
  }
}
