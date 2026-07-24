import 'package:flutter/material.dart';
import '../services/error_handler.dart';
import '../theme/app_colors.dart';

class ErrorSnackbar {
  static void show(BuildContext context, AppError error) {
    final color = _severityColor(error.severity);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(_severityIcon(error.severity), color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(error.message, style: const TextStyle(color: Colors.white, fontSize: 14)),
                  if (error.isRetryable) ...[
                    const SizedBox(height: 4),
                    Text('Tap to retry', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                  ],
                ],
              ),
            ),
            if (error.isRetryable)
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Retry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  static void showMessage(BuildContext context, String message, {Color? color, IconData? icon}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon ?? Icons.info_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
          ],
        ),
        backgroundColor: color ?? AppColors.primary,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static void showSuccess(BuildContext context, String message) {
    showMessage(context, message, color: AppColors.success, icon: Icons.check_circle_outline);
  }

  static void showError(BuildContext context, String message) {
    showMessage(context, message, color: AppColors.error, icon: Icons.error_outline);
  }

  static Color _severityColor(AppErrorSeverity severity) {
    switch (severity) {
      case AppErrorSeverity.low:
        return AppColors.primary;
      case AppErrorSeverity.medium:
        return AppColors.error;
      case AppErrorSeverity.high:
        return AppColors.error;
      case AppErrorSeverity.critical:
        return const Color(0xFFB71C1C);
    }
  }

  static IconData _severityIcon(AppErrorSeverity severity) {
    switch (severity) {
      case AppErrorSeverity.low:
        return Icons.info_outline;
      case AppErrorSeverity.medium:
        return Icons.warning_amber_rounded;
      case AppErrorSeverity.high:
        return Icons.error_outline;
      case AppErrorSeverity.critical:
        return Icons.report;
    }
  }
}

class ErrorDialog {
  static Future<void> show(
    BuildContext context,
    AppError error, {
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.error, size: 24),
            const SizedBox(width: 8),
            const Text('Error'),
          ],
        ),
        content: Text(error.message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDismiss?.call();
            },
            child: const Text('OK'),
          ),
          if (error.isRetryable && onRetry != null)
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                onRetry.call();
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
            ),
        ],
      ),
    );
  }

  static Future<void> showCritical(
    BuildContext context,
    String message, {
    required VoidCallback onSignOut,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.report, color: Color(0xFFB71C1C), size: 24),
            const SizedBox(width: 8),
            const Text('Session Expired'),
          ],
        ),
        content: const Text('Your session has expired. Please sign in again.'),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              onSignOut.call();
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sign In Again'),
          ),
        ],
      ),
    );
  }
}

class InlineError extends StatelessWidget {
  final String message;
  final bool isRetryable;
  final VoidCallback? onRetry;

  const InlineError({
    super.key,
    required this.message,
    this.isRetryable = false,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(message, style: const TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w500)),
                if (isRetryable && onRetry != null) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 32,
                    child: OutlinedButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Retry', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RetryWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const RetryWidget({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 48, color: AppColors.textTertiaryLight),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondaryLight)),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

class LoadingButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;
  final String label;
  final String? loadingLabel;
  final IconData? icon;

  const LoadingButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
    required this.label,
    this.loadingLabel,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                  if (loadingLabel != null) ...[
                    const SizedBox(width: 12),
                    Text(loadingLabel!, style: const TextStyle(fontSize: 16)),
                  ],
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(label, style: const TextStyle(fontSize: 16)),
                ],
              ),
      ),
    );
  }
}

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.3),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    if (message != null) ...[
                      const SizedBox(height: 16),
                      Text(message!, style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
