import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:learn_to_talk/core/services/app_initializer.dart';

// Data sources
import 'package:learn_to_talk/data/datasources/speech_recognition_data_source.dart';
import 'package:learn_to_talk/data/datasources/text_to_speech_data_source.dart';
import 'package:learn_to_talk/data/datasources/translation_data_source.dart';
import 'package:learn_to_talk/data/datasources/practice_data_source.dart';

// Repositories
import 'package:learn_to_talk/data/repositories/speech_recognition_repository_impl.dart';
import 'package:learn_to_talk/data/repositories/text_to_speech_repository_impl.dart';
import 'package:learn_to_talk/data/repositories/translation_repository_impl.dart';
import 'package:learn_to_talk/data/repositories/practice_repository_impl.dart';

// Domain repositories
import 'package:learn_to_talk/domain/repositories/speech_recognition_repository.dart';
import 'package:learn_to_talk/domain/repositories/text_to_speech_repository.dart';
import 'package:learn_to_talk/domain/repositories/translation_repository.dart';
import 'package:learn_to_talk/domain/repositories/practice_repository.dart';
import 'package:learn_to_talk/domain/repositories/speech_repository.dart';
import 'package:learn_to_talk/domain/repositories/tts_repository.dart';

// Repository adapters
import 'package:learn_to_talk/data/repositories/speech_repository_adapter.dart';
import 'package:learn_to_talk/data/repositories/tts_repository_adapter.dart';

// Use cases
import 'package:learn_to_talk/domain/usecases/get_languages_usecase.dart';
import 'package:learn_to_talk/domain/usecases/speech_recognition_usecase.dart';
import 'package:learn_to_talk/domain/usecases/text_to_speech_usecase.dart';
import 'package:learn_to_talk/domain/usecases/translation_usecase.dart';
import 'package:learn_to_talk/domain/usecases/practice_usecase.dart';

// BLoCs
import 'package:learn_to_talk/presentation/blocs/language/language_bloc.dart';
import 'package:learn_to_talk/presentation/blocs/speech/speech_bloc.dart';
import 'package:learn_to_talk/presentation/blocs/tts/tts_bloc.dart';
import 'package:learn_to_talk/presentation/blocs/translation/translation_bloc.dart';
import 'package:learn_to_talk/presentation/blocs/practice/practice_bloc.dart';

// Pages
import 'package:learn_to_talk/presentation/pages/home/home_page.dart';

final getIt = GetIt.instance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize app services (logging, etc.)
  await AppInitializer.init();
  
  // Setup dependency injection
  setupDependencies();
  
  runApp(const MyApp());
}

void setupDependencies() {
  // Data sources
  getIt.registerLazySingleton<SpeechRecognitionDataSource>(() => SpeechRecognitionDataSource());
  getIt.registerLazySingleton<TextToSpeechDataSource>(() => TextToSpeechDataSource());
  getIt.registerLazySingleton<TranslationDataSource>(() => TranslationDataSource());
  // Practice data source is already implemented
  getIt.registerLazySingleton<PracticeDataSource>(() => PracticeDataSource());
  
  // Repositories
  // Register original repositories
  getIt.registerLazySingleton<SpeechRecognitionRepository>(
    () => SpeechRecognitionRepositoryImpl(getIt<SpeechRecognitionDataSource>()));
  getIt.registerLazySingleton<TextToSpeechRepository>(
    () => TextToSpeechRepositoryImpl(getIt<TextToSpeechDataSource>()));
    
  // Register adapter repositories to bridge interfaces
  getIt.registerLazySingleton<SpeechRepository>(
    () => SpeechRepositoryAdapter(getIt<SpeechRecognitionRepository>()));
  getIt.registerLazySingleton<TTSRepository>(
    () => TTSRepositoryAdapter(getIt<TextToSpeechRepository>()));
  getIt.registerLazySingleton<TranslationRepository>(
    () => TranslationRepositoryImpl(getIt<TranslationDataSource>()));
  getIt.registerLazySingleton<PracticeRepository>(
    () => PracticeRepositoryImpl(getIt<PracticeDataSource>()));
  
  // Use cases
  getIt.registerLazySingleton(() => GetLanguagesUseCase(
    speechRepository: getIt<SpeechRepository>(),
    ttsRepository: getIt<TTSRepository>(),
    translationRepository: getIt<TranslationRepository>(),
  ));
  getIt.registerLazySingleton(() => SpeechRecognitionUseCase(
    speechRepository: getIt<SpeechRepository>(),
  ));
  getIt.registerLazySingleton(() => TextToSpeechUseCase(
    ttsRepository: getIt<TTSRepository>(),
  ));
  getIt.registerLazySingleton(() => TranslationUseCase(
    translationRepository: getIt<TranslationRepository>(),
  ));
  getIt.registerLazySingleton(() => PracticeUseCase(
    practiceRepository: getIt<PracticeRepository>(),
  ));
  
  // BLoCs
  getIt.registerFactory(() => LanguageBloc(
    getLanguagesUseCase: getIt<GetLanguagesUseCase>(),
    translationUseCase: getIt<TranslationUseCase>(),
  ));
  getIt.registerFactory(() => SpeechBloc(
    speechRecognitionUseCase: getIt<SpeechRecognitionUseCase>(),
  ));
  getIt.registerFactory(() => TTSBloc(
    ttsUseCase: getIt<TextToSpeechUseCase>(),
  ));
  getIt.registerFactory(() => TranslationBloc(
    translationUseCase: getIt<TranslationUseCase>(),
  ));
  getIt.registerFactory(() => PracticeBloc(
    practiceUseCase: getIt<PracticeUseCase>(),
    speechRecognitionUseCase: getIt<SpeechRecognitionUseCase>(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<LanguageBloc>(
          create: (_) => getIt<LanguageBloc>(),
        ),
        BlocProvider<SpeechBloc>(
          create: (_) => getIt<SpeechBloc>(),
        ),
        BlocProvider<TTSBloc>(
          create: (_) => getIt<TTSBloc>(),
        ),
        BlocProvider<TranslationBloc>(
          create: (_) => getIt<TranslationBloc>(),
        ),
        BlocProvider<PracticeBloc>(
          create: (_) => getIt<PracticeBloc>(),
        ),
      ],
      child: MaterialApp(
        title: 'Learn to Talk',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 2,
            ),
          ),
          cardTheme: CardTheme(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        home: const HomePage(),
      ),
    );
  }
}
