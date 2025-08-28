import 'package:flutter/material.dart';
import '../../core/errors/app_error.dart';

class AppErrorWidget extends StatelessWidget {
  final AppError error;
  final VoidCallback? onRetry;
  final String? customMessage;

  const AppErrorWidget({
    super.key,
    required this.error,
    this.onRetry,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.error,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildErrorIcon(),
          const SizedBox(height: 16),
          _buildErrorTitle(),
          const SizedBox(height: 8),
          _buildErrorMessage(),
          const SizedBox(height: 12),
          _buildErrorDetails(),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            _buildRetryButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorIcon() {
    IconData iconData;
    Color iconColor;

    if (error is NetworkError) {
      iconData = Icons.wifi_off;
      iconColor = Colors.red;
    } else if (error is CacheError) {
      iconData = Icons.storage;
      iconColor = Colors.orange;
    } else if (error is ValidationError) {
      iconData = Icons.verified_user;
      iconColor = Colors.amber;
    } else if (error is DataParsingError) {
      iconData = Icons.code;
      iconColor = Colors.purple;
    } else {
      iconData = Icons.error_outline;
      iconColor = Colors.grey;
    }

    return Icon(
      iconData,
      size: 48,
      color: iconColor,
    );
  }

  Widget _buildErrorTitle() {
    String title;

    if (error is NetworkError) {
      title = 'Ошибка сети';
    } else if (error is CacheError) {
      title = 'Ошибка кэша';
    } else if (error is ValidationError) {
      title = 'Ошибка валидации';
    } else if (error is DataParsingError) {
      title = 'Ошибка парсинга';
    } else {
      title = 'Неизвестная ошибка';
    }

    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildErrorMessage() {
    final message = customMessage ?? error.message;

    return Text(
      message,
      style: const TextStyle(
        fontSize: 16,
        color: Colors.red,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildErrorDetails() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Детали ошибки:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildDetailRow('Тип ошибки', error.runtimeType.toString()),
          if (error.details != null)
            _buildDetailRow('Описание', error.details!),
          if (error.stackTrace != null)
            _buildDetailRow('Stack Trace', error.stackTrace.toString()),
          ..._buildSpecificErrorDetails(),
        ],
      ),
    );
  }

  List<Widget> _buildSpecificErrorDetails() {
    final widgets = <Widget>[];

    if (error is NetworkError) {
      final networkError = error as NetworkError;
      if (networkError.statusCode != null) {
        widgets.add(
            _buildDetailRow('HTTP код', networkError.statusCode.toString()));
      }
      final url = networkError.url;
      if (url != null) {
        widgets.add(_buildDetailRow('URL', url));
      }
    } else if (error is ValidationError) {
      final validationError = error as ValidationError;
      if (validationError.field != null) {
        widgets.add(_buildDetailRow('Поле', validationError.field!));
      }
      if (validationError.expectedValue != null) {
        widgets.add(_buildDetailRow(
            'Ожидаемое значение', validationError.expectedValue.toString()));
      }
    } else if (error is CacheError) {
      final cacheError = error as CacheError;
      if (cacheError.operation != null) {
        widgets.add(_buildDetailRow('Операция', cacheError.operation!));
      }
    } else if (error is DataParsingError) {
      final parsingError = error as DataParsingError;
      if (parsingError.source != null) {
        widgets.add(_buildDetailRow('Источник', parsingError.source!));
      }
    }

    return widgets;
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRetryButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh),
        label: const Text('Повторить'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
