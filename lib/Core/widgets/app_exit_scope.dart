import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:erp_app/Core/widgets/app_confirm_dialog.dart';

/// Wrap the root (home) screen of a role.
/// Back press on it asks for confirmation before closing the app.
class AppExitScope extends StatelessWidget {
  const AppExitScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final exit = await AppConfirmDialog.show(
          context,
          icon: Icons.exit_to_app_rounded,
          title: 'Exit app?',
          message: 'Are you sure you want to exit the app?',
          confirmText: 'Exit',
          cancelText: 'Stay',
          compact: true,
        );
        if (exit) SystemNavigator.pop();
      },
      child: child,
    );
  }
}