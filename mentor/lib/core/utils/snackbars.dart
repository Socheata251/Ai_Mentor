import 'package:flutter/material.dart';

void showComingSoon(BuildContext context, String what) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text('$what is coming soon'),
      duration: const Duration(seconds: 2),
    ));
}
