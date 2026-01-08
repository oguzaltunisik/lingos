import 'package:flutter/material.dart';
import 'package:lingos/services/language_service.dart';
import 'package:lingos/pages/language_selection_page.dart';
import 'package:lingos/pages/home_page.dart';

class GatePage extends StatefulWidget {
  const GatePage({super.key});

  @override
  State<GatePage> createState() => _GatePageState();
}

class _GatePageState extends State<GatePage> {
  bool _isLoading = true;
  bool _needsLanguageSelection = false;

  @override
  void initState() {
    super.initState();
    _checkLanguageSelection();
  }

  Future<void> _checkLanguageSelection() async {
    final isCompleted = await LanguageService.isLanguageSelectionCompleted();

    if (!mounted) return;

    setState(() {
      _needsLanguageSelection = !isCompleted;
      _isLoading = false;
    });
  }

  void _onLanguageSelectionCompleted() {
    // Re-check language selection when completed
    _checkLanguageSelection();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Build the appropriate page directly instead of navigating
    if (_needsLanguageSelection) {
      return LanguageSelectionPage(
        onLanguageSelected: _onLanguageSelectionCompleted,
      );
    } else {
      return const HomePage();
    }
  }
}
