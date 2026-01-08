import 'package:flutter/material.dart';
import 'package:lingos/services/language_service.dart';
import 'package:lingos/services/app_localizations.dart';

class LanguageSelectionPage extends StatefulWidget {
  final VoidCallback? onLanguageSelected;

  const LanguageSelectionPage({super.key, this.onLanguageSelected});

  @override
  State<LanguageSelectionPage> createState() => _LanguageSelectionPageState();
}

class _LanguageSelectionPageState extends State<LanguageSelectionPage> {
  String? _selectedNativeLanguage;
  String? _selectedTargetLanguage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedLanguages();
  }

  Future<void> _loadSavedLanguages() async {
    final nativeLang = await LanguageService.getNativeLanguage();
    final targetLang = await LanguageService.getTargetLanguage();

    setState(() {
      _selectedNativeLanguage = nativeLang;
      _selectedTargetLanguage = targetLang;
    });
  }

  Future<void> _saveLanguages() async {
    final localizations = AppLocalizations.current;

    if (_selectedNativeLanguage == null || _selectedTargetLanguage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.selectBothLanguages)),
      );
      return;
    }

    if (_selectedNativeLanguage == _selectedTargetLanguage) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.languagesMustBeDifferent)),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await LanguageService.setNativeLanguage(_selectedNativeLanguage!);
      await LanguageService.setTargetLanguage(_selectedTargetLanguage!);

      // Set app UI language to native language
      await LanguageService.setAppLanguage(_selectedNativeLanguage!);

      if (!mounted) return;

      // Notify parent (gate page or home page) that language selection is completed
      widget.onLanguageSelected?.call();

      // If opened from home page (Navigator can pop), pop back
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;

      final localizations = AppLocalizations.current;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${localizations.errorSavingLanguages}$e')),
      );

      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildLanguageSelector({
    required String title,
    required String? selectedLanguage,
    required Function(String) onLanguageSelected,
    required bool isNativeLanguage,
    required AppLocalizations localizations,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        ...LanguageService.supportedLanguages.map((lang) {
          final isSelected = selectedLanguage == lang;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: InkWell(
              onTap: () => onLanguageSelected(lang),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: isSelected
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${LanguageService.getLanguageEmoji(lang)} ${localizations.getLanguageDisplayName(lang)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    else
                      const Icon(Icons.circle_outlined),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguageService.appLanguageNotifier,
      builder: (context, languageCode, child) {
        final localizations = AppLocalizations(languageCode);

        return Scaffold(
          appBar: AppBar(title: Text(localizations.selectLanguages)),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                _buildLanguageSelector(
                  title: localizations.nativeLanguageTitle,
                  selectedLanguage: _selectedNativeLanguage,
                  onLanguageSelected: (lang) async {
                    setState(() {
                      _selectedNativeLanguage = lang;
                      // If native language is same as target language, reset target language
                      if (_selectedTargetLanguage == lang) {
                        _selectedTargetLanguage = null;
                      }
                    });
                    // Update UI language immediately when native language is selected
                    LanguageService.appLanguageNotifier.value = lang;
                  },
                  isNativeLanguage: true,
                  localizations: localizations,
                ),
                const SizedBox(height: 32),
                _buildLanguageSelector(
                  title: localizations.targetLanguageTitle,
                  selectedLanguage: _selectedTargetLanguage,
                  onLanguageSelected: (lang) {
                    setState(() {
                      _selectedTargetLanguage = lang;
                      // If target language is same as native language, reset native language
                      if (_selectedNativeLanguage == lang) {
                        _selectedNativeLanguage = null;
                      }
                    });
                  },
                  isNativeLanguage: false,
                  localizations: localizations,
                ),
                const SizedBox(height: 48),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveLanguages,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          localizations.continueButton,
                          style: const TextStyle(fontSize: 18),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
