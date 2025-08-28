import 'package:equatable/equatable.dart';

abstract class AppError extends Equatable {
  final String message;
  final String? details;
  final StackTrace? stackTrace;

  const AppError({
    required this.message,
    this.details,
    this.stackTrace,
  });

  @override
  List<Object?> get props => [message, details, stackTrace];

  @override
  String toString() {
    final detailsText = details != null ? ' ($details)' : '';
    return '$runtimeType: $message$detailsText';
  }
}

class NetworkError extends AppError {
  final int? statusCode;
  final String? url;

  const NetworkError({
    required super.message,
    this.statusCode,
    this.url,
    super.details,
    super.stackTrace,
  });

  @override
  List<Object?> get props => [...super.props, statusCode, url];

  @override
  String toString() {
    final statusInfo = statusCode != null ? ' (Status: $statusCode)' : '';
    final urlInfo = url != null ? ' URL: $url' : '';
    return 'NetworkError: $message$statusInfo$urlInfo';
  }

  factory NetworkError.fromHttpException(
      String message, int? statusCode, String? url) {
    String userMessage;
    switch (statusCode) {
      case 400:
        userMessage = 'Неверный запрос';
        break;
      case 401:
        userMessage = 'Не авторизован';
        break;
      case 403:
        userMessage = 'Доступ запрещен';
        break;
      case 404:
        userMessage = 'Данные не найдены';
        break;
      case 500:
        userMessage = 'Ошибка сервера';
        break;
      case 502:
        userMessage = 'Сервер временно недоступен';
        break;
      case 503:
        userMessage = 'Сервис временно недоступен';
        break;
      default:
        userMessage = 'Ошибка сети';
    }

    return NetworkError(
      message: userMessage,
      statusCode: statusCode,
      url: url,
      details: message,
    );
  }

  factory NetworkError.noConnection() {
    return const NetworkError(
      message: 'Нет подключения к интернету',
      details: 'Проверьте подключение к сети и попробуйте снова',
    );
  }

  factory NetworkError.timeout() {
    return const NetworkError(
      message: 'Превышено время ожидания',
      details: 'Запрос выполняется слишком долго. Попробуйте снова',
    );
  }
}

class CacheError extends AppError {
  final String? operation;

  const CacheError({
    required super.message,
    this.operation,
    super.details,
    super.stackTrace,
  });

  @override
  List<Object?> get props => [...super.props, operation];

  factory CacheError.readError(String details) {
    return CacheError(
      message: 'Ошибка чтения кэша',
      operation: 'read',
      details: details,
    );
  }

  factory CacheError.writeError(String details) {
    return CacheError(
      message: 'Ошибка записи в кэш',
      operation: 'write',
      details: details,
    );
  }

  factory CacheError.deleteError(String details) {
    return CacheError(
      message: 'Ошибка удаления из кэша',
      operation: 'delete',
      details: details,
    );
  }
}

class ValidationError extends AppError {
  final String field;
  final String? expectedValue;

  const ValidationError({
    required super.message,
    required this.field,
    this.expectedValue,
    super.details,
    super.stackTrace,
  });

  @override
  List<Object?> get props => [...super.props, field, expectedValue];

  factory ValidationError.invalidField(String field, String details) {
    return ValidationError(
      message: 'Некорректные данные в поле "$field"',
      field: field,
      details: details,
    );
  }

  factory ValidationError.missingField(String field) {
    return ValidationError(
      message: 'Отсутствует обязательное поле "$field"',
      field: field,
    );
  }
}

class UnknownError extends AppError {
  const UnknownError({
    required super.message,
    super.details,
    super.stackTrace,
  });

  factory UnknownError.fromException(
      dynamic exception, StackTrace? stackTrace) {
    return UnknownError(
      message: 'Неизвестная ошибка',
      details: exception.toString(),
      stackTrace: stackTrace,
    );
  }
}

class DataParsingError extends AppError {
  final String? source;

  const DataParsingError({
    required super.message,
    this.source,
    super.details,
    super.stackTrace,
  });

  @override
  List<Object?> get props => [...super.props, source];

  factory DataParsingError.invalidJson(String details) {
    return DataParsingError(
      message: 'Ошибка парсинга данных',
      details: details,
    );
  }

  factory DataParsingError.missingRequiredField(String field, String source) {
    return DataParsingError(
      message: 'Отсутствует обязательное поле "$field"',
      source: source,
      details: 'Поле "$field" не найдено в данных из $source',
    );
  }
}
