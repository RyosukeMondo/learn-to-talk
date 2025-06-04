import 'package:equatable/equatable.dart';

class Language extends Equatable {
  final String code;
  final String name;
  final bool isOfflineAvailable;

  const Language({
    required this.code,
    required this.name,
    required this.isOfflineAvailable,
  });

  @override
  List<Object> get props => [code, name, isOfflineAvailable];
}
