import 'package:erp_app/api_manager/api_checker.dart';
import 'package:erp_app/api_manager/api_client.dart';
import 'package:erp_app/api_manager/api_endPoints.dart';
import 'package:erp_app/Core/widgets/app_confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bookmark icon for AppBar. Adds or removes this page from Quick Links.
class QuickLinkBookmarkButton extends StatefulWidget {
  const QuickLinkBookmarkButton({super.key, required this.menuUniqueId});

  final int menuUniqueId;

  @override
  State<QuickLinkBookmarkButton> createState() =>
      _QuickLinkBookmarkButtonState();
}

class _QuickLinkBookmarkButtonState extends State<QuickLinkBookmarkButton> {
  final ApiClient _api = ApiClient();
  int? _linkId; // saved quick link id, null if not saved
  bool _busy = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<int?> _userId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id');
  }

  // Check if this page is already saved
  Future<void> _load() async {
    final userId = await _userId();
    if (userId == null) {
      if (mounted) setState(() => _busy = false);
      return;
    }
    final res = await _api.getData(ApiEndPoints.quickLinksByUser(userId));
    int? found;
    if (ApiChecker.checkApi(res) == null && res.body is List) {
      for (final item in res.body as List) {
        if (item is Map &&
            (item['menuUniqueId'] as num?)?.toInt() == widget.menuUniqueId) {
          found = (item['id'] as num?)?.toInt();
          break;
        }
      }
    }
    if (!mounted) return;
    setState(() {
      _linkId = found;
      _busy = false;
    });
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(color: Colors.black),
          ),
          backgroundColor: Colors.white,
        ),
      );
  }

  Future<void> _toggle() async {
    final saved = _linkId != null;
    final ok = await AppConfirmDialog.show(
      context,
      icon: saved ? Icons.bookmark_remove_outlined : Icons.bookmark_add_outlined,
      title: saved ? 'Remove Quick Link' : 'Add Quick Link',
      message: saved
          ? 'Remove this page from your Quick Links?'
          : 'Add this page to your Quick Links?',
      confirmText: saved ? 'Remove' : 'Add',
      cancelText: 'Cancel',
      compact: true,
    );
    if (!ok || !mounted) return;

    setState(() => _busy = true);
    final userId = await _userId();
    if (userId == null) {
      if (!mounted) return;
      setState(() => _busy = false);
      _snack('Please login again.');
      return;
    }

    final res = saved
        ? await _api.deleteData(ApiEndPoints.deleteQuickLink(_linkId!))
        : await _api.postData(
            '${ApiEndPoints.quickLinks}?userId=$userId&menuUniqueId=${widget.menuUniqueId}',
            authenticated: true,
          );
    final error = ApiChecker.checkApi(res);
    if (!mounted) return;
    if (error != null) {
      setState(() => _busy = false);
      _snack(error);
      return;
    }
    _snack(saved ? 'Removed from Quick Links' : 'Added to Quick Links');
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Quick Link',
      onPressed: _busy ? () {} : _toggle,
      icon: Icon(_linkId != null ? Icons.bookmark : Icons.bookmark_border),
    );
  }
}