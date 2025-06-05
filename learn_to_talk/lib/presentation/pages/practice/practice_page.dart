import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:learn_to_talk/domain/entities/practice.dart';
import 'package:learn_to_talk/presentation/blocs/practice/practice_bloc.dart';
import 'package:learn_to_talk/presentation/blocs/practice/practice_event.dart';
import 'package:learn_to_talk/presentation/blocs/practice/practice_state.dart';
import 'package:learn_to_talk/presentation/widgets/practice_item_widget.dart';
import 'package:learn_to_talk/presentation/pages/practice/practice_session_page.dart';

class PracticePage extends StatefulWidget {
  final String sourceLanguageCode;
  final String targetLanguageCode;

  const PracticePage({
    super.key,
    required this.sourceLanguageCode,
    required this.targetLanguageCode,
  });

  @override
  State<PracticePage> createState() => _PracticePageState();
}

class _PracticePageState extends State<PracticePage> {
  @override
  void initState() {
    super.initState();
    _loadPractices();
  }

  void _loadPractices() {
    context.read<PracticeBloc>().add(LoadPractices(
      sourceLanguageCode: widget.sourceLanguageCode,
      targetLanguageCode: widget.targetLanguageCode,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Practice'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPractices,
            tooltip: 'Refresh practices',
          ),
        ],
      ),
      body: BlocBuilder<PracticeBloc, PracticeState>(
        builder: (context, state) {
          if (state.status == PracticeStatus.loading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state.status == PracticeStatus.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.errorMessage ?? 'An error occurred loading practices',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadPractices,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state.practices.isEmpty) {
            return _buildEmptyState();
          }

          return _buildPracticeList(context, state.practices);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCreatePractice(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Practice'),
        heroTag: 'practice_page_fab',
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.menu_book,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No practice items yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first practice item to get started',
            style: TextStyle(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _navigateToCreatePractice(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Practice'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildPracticeList(BuildContext context, List<Practice> practices) {
    return Column(
      children: [
        _buildStartSessionButton(context, practices),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: practices.length,
            itemBuilder: (context, index) {
              final practice = practices[index];
              return PracticeItemWidget(
                practice: practice,
                onPracticeSelected: (practice) => _initiatePracticeSessionAndNavigate(context, [practice]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStartSessionButton(BuildContext context, List<Practice> practices) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: ElevatedButton.icon(
        onPressed: practices.isNotEmpty 
            ? () => _startPracticeSession(context, practices) 
            : null,
        icon: const Icon(Icons.play_arrow),
        label: const Text('Start Practice Session'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  /// Start a practice session with the given practices
  /// This method handles the async flow properly by capturing context references
  /// before any async operation to avoid BuildContext across async gap warnings
  void _startPracticeSession(BuildContext context, List<Practice> practices) {
    _initiatePracticeSessionAndNavigate(context, practices);
  }
  
  /// Private helper to initiate a practice session and navigate
  /// Extracted to follow DRY principle and improve maintainability
  void _initiatePracticeSessionAndNavigate(BuildContext context, List<Practice> practices) {
    final practiceBloc = context.read<PracticeBloc>();
    practiceBloc.add(StartPracticeSession(
      sourceLanguageCode: widget.sourceLanguageCode,
      targetLanguageCode: widget.targetLanguageCode,
    ));
    
    // Store context reference before async gap
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    
    // Wait for the session to be created then navigate
    practiceBloc.stream.firstWhere(
      (state) => state.currentSessionId != null,
    ).then((state) {
      if (!mounted) return;
      
      final sessionId = state.currentSessionId;
      if (sessionId == null) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Could not start practice session')),
        );
        return;
      }
      
      // Navigate to practice session screen
      navigator.push(
        MaterialPageRoute(
          builder: (context) => PracticeSessionPage(
            sessionId: sessionId,
            practices: practices,
            sourceLanguageCode: widget.sourceLanguageCode,
            targetLanguageCode: widget.targetLanguageCode,
          ),
        ),
      );
    });
  }



  void _navigateToCreatePractice(BuildContext context) {
    // Will implement this in create_practice_page.dart
    // For now, just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create practice feature coming soon')),
    );
  }
}
