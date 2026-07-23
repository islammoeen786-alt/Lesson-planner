import 'package:flutter/material.dart';

class AppBottomSheet {
  static Future<T?> show<T>(BuildContext context, {
    required Widget child,
    String? title,
    double initialChildSize = 0.6,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: initialChildSize,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Row(
                  children: [
                    Container(width: 32, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                    const Spacer(),
                    if (title != null) Text(title, style: Theme.of(ctx).textTheme.titleMedium),
                    const Spacer(),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
              ),
              Expanded(
                child: ListView(controller: scrollController, padding: const EdgeInsets.fromLTRB(20, 0, 20, 20), children: [child]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
