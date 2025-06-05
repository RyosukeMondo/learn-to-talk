import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:learn_to_talk/presentation/blocs/language/language_bloc.dart';
import 'package:learn_to_talk/presentation/blocs/language/language_state.dart';
import 'package:learn_to_talk/presentation/pages/language_selection/language_selection_page.dart';
import 'package:learn_to_talk/presentation/pages/practice/practice_page.dart';
import 'package:learn_to_talk/presentation/pages/translation/translation_page.dart';
import 'package:learn_to_talk/presentation/pages/practice/create_practice_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final List<Widget> _pages = [];
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    // Pages will be initialized once we know the language selection state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndInitPages();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _initPages(String sourceLanguageCode, String targetLanguageCode) {
    if (mounted) {
      setState(() {
        _pages.clear();
        _pages.addAll([
          PracticePage(
            sourceLanguageCode: sourceLanguageCode,
            targetLanguageCode: targetLanguageCode,
          ),
          const TranslationPage(),
        ]);
      });
    }
  }
  
  void _checkAndInitPages() {
    final state = context.read<LanguageBloc>().state;
    if (_pages.isEmpty && 
        state.sourceLanguage != null && 
        state.targetLanguage != null) {
      _initPages(
        state.sourceLanguage!.code,
        state.targetLanguage!.code,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageBloc, LanguageState>(
      builder: (context, state) {
        // Check if language selection is complete
        if (!state.isLanguagePairSelected) {
          return LanguageSelectionPage(
            showBackButton: false, // Hide back button on first launch
            onLanguagePairSelected: () {
              // Use addPostFrameCallback to defer the setState call until after build
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (state.sourceLanguage != null && state.targetLanguage != null) {
                  _initPages(
                    state.sourceLanguage!.code,
                    state.targetLanguage!.code,
                  );
                }
              });
            },
          );
        }

        // Initialize pages if not already done
        if (_pages.isEmpty && state.sourceLanguage != null && state.targetLanguage != null) {
          // Use addPostFrameCallback to defer the setState call until after build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _initPages(
              state.sourceLanguage!.code,
              state.targetLanguage!.code,
            );
          });
        }

        return Scaffold(
          body: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: _pages,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
          appBar: AppBar(
            title: const Text('Learn to Talk'),
            actions: [
              IconButton(
                icon: const Icon(Icons.language),
                tooltip: 'Language Settings',
                onPressed: () => _navigateToLanguageSettings(context),
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                tooltip: 'Settings',
                onPressed: () {
                  // TODO: Implement additional settings page if needed
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Settings coming soon')),
                  );
                },
              ),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
                _pageController.jumpToPage(index);
              });
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.school),
                label: 'Practice',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.translate),
                label: 'Translate',
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _navigateToCreatePractice(context, state),
            tooltip: 'Create Practice Item',
            heroTag: 'home_page_fab',
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  void _navigateToCreatePractice(BuildContext context, LanguageState state) {
    if (state.sourceLanguage != null && state.targetLanguage != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CreatePracticePage(
            initialSourceLanguageCode: state.sourceLanguage!.code,
            initialTargetLanguageCode: state.targetLanguage!.code,
          ),
        ),
      );
    }
  }
  
  void _navigateToLanguageSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const LanguageSelectionPage(
          showBackButton: true,
        ),
      ),
    );
  }
}
